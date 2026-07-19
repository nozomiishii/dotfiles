---
name: cloud-bump
description: >-
  claude.ai の cloud 環境の init_script を内部 API で更新し、
  環境スナップショットの再構築を発火させる。
  Claude Code で /cloud-bump、Codex で $cloud-bump と入力したとき、または dotfiles の main にマージした変更が
  cloud 配信対象 (cloud-setup.yaml の paths) に触れていたときに使用する。
model: sonnet
allowed-tools: mcp__claude-in-chrome__javascript_tool
---

# /cloud-bump

cloud 環境の setup script は毎セッション走らない。環境スナップショットの再構築時にだけ走り、再構築のトリガーは Setup script 欄の変更・allowed network hosts の変更・約 7 日のキャッシュ失効だけ ([Environment caching](https://code.claude.com/docs/en/claude-code-on-the-web#environment-caching))。main にマージして tarball が再デプロイされても、bump しない限り新規セッションは最大 7 日前のスナップショットで起動する。「マージされたので自動で反映済み」は誤り。設計の経緯は [dotfiles#1347](https://github.com/nozomiishii/dotfiles/issues/1347)。

## 発火の判定

対象は main にマージ済みの変更だけ。マージ前に bump すると古い main でスナップショットが焼き直されるだけになる。

判定リストの正本は `.github/workflows/cloud-setup.yaml` の `paths`。スキルに書き写さず、workflow ファイルを読んで merge diff と突き合わせる。触れていなければ bump 不要と伝えて終わる。

## 権限

- Claude Code: JS 実行の許可は frontmatter の allowed-tools で与える。settings.json に javascript_tool の常時 allow を置かない。許可はこのスキルを起動したターンだけ有効で、次のユーザーメッセージで消れる ([skills.md](https://code.claude.com/docs/en/skills.md))。承認待ちでターンをまたいだら、POST の前にスキルを起動し直して許可を再適用する
- Codex: 最初に `$chrome:control-chrome` を読み、既存の Chrome セッションを選ぶ。本文の `javascript_tool`、`read_network_requests`、UI 操作を literal なツール名として呼ばず、browser-client の Playwright 評価・ネットワーク観察・クリックへ読み替える。最初に、page origin への GET と POST、ネットワーク観察を実行できる capability があるか確認する。capability が欠けていれば API 操作を試さず停止し、手動フォールバック URL を案内する。承認でターンをまたいだら `$cloud-bump` を再度読み、Chrome 接続と GET 結果を再確認してから POST する

どちらの環境でも POST 前の差分承認を省略しない。

Claude Code / Codex とも、`claude.ai/code` を開いた tab ID と bootstrap URL を最初に固定する。全 read、network 観察、fetch、click の直前に、固定した tab ID・`https://claude.ai` origin・`/code` で始まる path が一致することを確認する。不一致なら環境設定を送受信せず停止する。

Codex で承認を求めるときは、ユーザーへ「`$cloud-bump 承認` と返信してください」と案内して turn を終える。次の発話で skill を明示的に再起動し、Chrome 接続と GET 結果が承認前と一致することを確認してから POST する。単なる「承認します」という返信を、skill を再読せずに処理しない。

## init_script の更新 (内部 API)

claude.ai の未文書化 API で init_script を直接更新する。公式 API ではないため、動かなくなったら「エンドポイントの再発見」セクションの手順で調査し直す。

### 手順

Claude in Chrome で <https://claude.ai/code> を開き、JS でAPI を叩く。

GET で現在の環境設定を取得:

```js
const assertClaudeContext = () => {
  if (location.origin !== 'https://claude.ai' || !location.pathname.startsWith('/code')) {
    throw new Error('unexpected tab origin or path');
  }
};
const canonicalize = value => Array.isArray(value)
  ? value.map(canonicalize)
  : value && typeof value === 'object'
    ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonicalize(value[key])]))
    : value;
const sha256 = async value => {
  const bytes = new TextEncoder().encode(JSON.stringify(canonicalize(value)));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
};
const orgId = '<network-log-derived-org-id>';
const envId = '<network-log-derived-env-id>';
if (!/^[A-Za-z0-9_-]{8,128}$/.test(orgId)) throw new Error('invalid orgId');
if (!/^[A-Za-z0-9_-]{8,128}$/.test(envId)) throw new Error('invalid envId');
const endpoint = `https://claude.ai/v1/environment_providers/private/organizations/${encodeURIComponent(orgId)}/environments/${encodeURIComponent(envId)}`;
assertClaudeContext();
const getResp = await fetch(endpoint);
if (!getResp.ok) throw new Error(`GET failed: ${getResp.status}`);
const env = await getResp.json();
const originalInit = String(env.config.init_script ?? '');
const now = new Date();
const pad = value => String(value).padStart(2, '0');
const proposedBumpLine = `# bump ${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
const snapshotDigest = await sha256(env);
({
  snapshotDigest,
  environmentId: env.environment_id ?? envId,
  name: env.name,
  currentBumpLine: originalInit.match(/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?=\n|$)/)?.[0] ?? null,
  proposedBumpLine
});
```

org_id と env_id は GET のレスポンス、または環境セレクタ操作時のネットワークログから取得する。環境が複数あるときは、どれを bump するかユーザーに確認する。

この GET call が返した `snapshotDigest`、環境名、現在の bump 行、`proposedBumpLine` だけを会話に控え、差分承認を得る。env 全体や `config.environment` を会話へ出さない。

承認後は別の JavaScript call で GET を再実行する。次の block の `approvedSnapshotDigest` と `approvedBumpLine` を承認済みの実値へ置換する。fresh GET の digest が一致した場合だけ、init_script の先頭行を更新して POST する。前の call の lexical binding は使わない。

```js
const assertClaudeContext = () => {
  if (location.origin !== 'https://claude.ai' || !location.pathname.startsWith('/code')) {
    throw new Error('unexpected tab origin or path');
  }
};
const canonicalize = value => Array.isArray(value)
  ? value.map(canonicalize)
  : value && typeof value === 'object'
    ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonicalize(value[key])]))
    : value;
const sha256 = async value => {
  const bytes = new TextEncoder().encode(JSON.stringify(canonicalize(value)));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
};
const orgId = '<network-log-derived-org-id>';
const envId = '<network-log-derived-env-id>';
const approvedSnapshotDigest = '<approved-snapshot-sha256>';
const approvedBumpLine = '<approved-bump-line>';
if (!/^[A-Za-z0-9_-]{8,128}$/.test(orgId)) throw new Error('invalid orgId');
if (!/^[A-Za-z0-9_-]{8,128}$/.test(envId)) throw new Error('invalid envId');
if (!/^[a-f0-9]{64}$/.test(approvedSnapshotDigest)) throw new Error('invalid approved snapshot digest');
if (!/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}$/.test(approvedBumpLine)) throw new Error('invalid approved bump line');
const endpoint = `https://claude.ai/v1/environment_providers/private/organizations/${encodeURIComponent(orgId)}/environments/${encodeURIComponent(envId)}`;

assertClaudeContext();
const getResp = await fetch(endpoint);
if (!getResp.ok) throw new Error(`GET failed: ${getResp.status}`);
const env = await getResp.json();
if (await sha256(env) !== approvedSnapshotDigest) {
  throw new Error('environment changed after approval');
}
const originalInit = String(env.config.init_script ?? '');
const bumpPattern = /^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?=\n|$)/;
const stripBump = value => value.replace(/^# bump \d{4}-\d{2}-\d{2} \d{2}:\d{2}(?:\n|$)/, '');
const updatedInit = bumpPattern.test(originalInit)
  ? originalInit.replace(bumpPattern, approvedBumpLine)
  : `${approvedBumpLine}\n${originalInit}`;

if (stripBump(updatedInit) !== stripBump(originalInit)) {
  throw new Error('init_script body changed outside the bump line');
}

const updated = {
  name: env.name,
  description: env.description,
  config: { ...env.config, init_script: updatedInit }
};
assertClaudeContext();
const resp = await fetch(endpoint, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(updated)
});
if (!resp.ok) throw new Error(`POST failed: ${resp.status}`);

assertClaudeContext();
const verifyResp = await fetch(endpoint);
if (!verifyResp.ok) throw new Error(`verification GET failed: ${verifyResp.status}`);
const after = await verifyResp.json();
const beforeRest = { ...env.config }; delete beforeRest.init_script;
const afterRest = { ...after.config }; delete afterRest.init_script;
if (after.config.init_script !== updatedInit ||
    after.name !== env.name || after.description !== env.description ||
    JSON.stringify(afterRest) !== JSON.stringify(beforeRest)) {
  throw new Error('POST verification mismatch');
}
```

- GET で現在の init_script を読み取り、会話に控える
- 承認前 call は safe summary と snapshot digest を返す。承認後 call は context guard、endpoint、GET、更新、検証 GET を自己完結させる
- 変更は先頭の日時コメント行 `# bump YYYY-MM-DD HH:MM` の追加・更新のみ。他の行に触れない。再構築のトリガーは欄のテキストが変わることなので、同日に複数回 bump しても変化が出るよう時刻まで書く
- POST 前に差分を提示して承認を得る
- POST 後は同じ endpoint を GET し、bump 行以外の init_script 本文と他 field が承認前の値から変わっていないことを検証する
- POST が失敗したら手動フォールバック: <https://claude.ai/code> で下部バーの環境タブ（雲アイコン）→ 歯車アイコン → 「Update cloud environment」ダイアログの Setup script 欄を手で書き換える

init_script が非 0 で終了する状態になると新規セッションが全て起動不能になる。欄を壊さないことを何より優先する。

### API レスポンス構造

```json
{
  "environment_id": "env_...",
  "name": "Default",
  "config": {
    "environment_type": "anthropic",
    "sub_type": "ccr",
    "cwd": "/home/user",
    "init_script": "# bump ...\ncurl ...",
    "environment": {},
    "languages": [{ "name": "python", "version": "3.11" }, ...],
    "network_config": { "allowed_hosts": ["*"], "allow_default_hosts": true }
  }
}
```

UI の「Setup script」は `config.init_script`、「Environment variables」は `config.environment`。

### POST リクエストの必須フィールド

`name`, `description`, `config` が必要。`description` を含む GET の既存値をそのまま返し、空文字列で上書きしない。

## エンドポイントの再発見

API が変更されて動かなくなった場合の調査手順。

- Claude in Chrome で <https://claude.ai/code> を開く
- ネットワーク観察が利用できることを確認し、ログをクリアする。利用できなければ手動フォールバック URL を案内して止まる
- 下部バーの環境タブ（雲アイコン）→ 歯車アイコンでダイアログを開く
- ダイアログを開いた時点の GET リクエストの URL からエンドポイントのパス・org_id・env_id が分かる
- ダイアログ表示と GET だけを観察する。Setup script や他の項目は変更せず、「Save changes」をクリックしない
- GET のレスポンスと、既存の frontend bundle 内の request 定義から method、URL、payload のフィールド名を確認する
- 読み取りだけで POST の仕様を特定できなければ、環境を変更せず手動フォールバック URL を案内して止まる。再発見のための試験 POST はユーザー承認前に行わない

## 反映範囲

再構築が効くのは bump 後に開始した新規セッションだけ。実行中・再開セッションには効かない。
