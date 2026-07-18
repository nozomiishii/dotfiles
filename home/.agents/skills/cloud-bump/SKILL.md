---
name: cloud-bump
description: >-
  claude.ai の cloud 環境の init_script を内部 API で更新し、
  環境スナップショットの再構築を発火させる。
  ユーザーが /cloud-bump と入力したとき、または dotfiles の main にマージした変更が
  cloud 配信対象 (cloud-setup.yaml の paths) に触れていたときに使用する。
model: sonnet
---

# /cloud-bump

cloud 環境の setup script は毎セッション走らない。環境スナップショットの再構築時にだけ走り、再構築のトリガーは Setup script 欄の変更・allowed network hosts の変更・約 7 日のキャッシュ失効だけ ([Environment caching](https://code.claude.com/docs/en/claude-code-on-the-web#environment-caching))。main にマージして tarball が再デプロイされても、bump しない限り新規セッションは最大 7 日前のスナップショットで起動する。「マージされたので自動で反映済み」は誤り。設計の経緯は [dotfiles#1347](https://github.com/nozomiishii/dotfiles/issues/1347)。

## 発火の判定

対象は main にマージ済みの変更だけ。マージ前に bump すると古い main でスナップショットが焼き直されるだけになる。

判定リストの正本は `.github/workflows/cloud-setup.yaml` の `paths`。スキルに書き写さず、workflow ファイルを読んで merge diff と突き合わせる。触れていなければ bump 不要と伝えて終わる。

## init_script の更新 (内部 API)

claude.ai の未文書化 API で init_script を直接更新する。公式 API ではないため、動かなくなったら「エンドポイントの再発見」セクションの手順で調査し直す。

### 手順

Claude in Chrome で https://claude.ai/code を開き、JS でAPI を叩く。

GET で現在の環境設定を取得:

```js
const resp = await fetch('/v1/environment_providers/private/organizations/{org_id}/environments/{env_id}');
const env = await resp.json();
```

org_id と env_id は GET のレスポンス、または環境セレクタ操作時のネットワークログから取得する。環境が複数あるときは、どれを bump するかユーザーに確認する。

init_script の先頭行だけ更新して POST:

```js
const updated = {
  name: env.name,
  description: "",
  config: { ...env.config, init_script: "# bump YYYY-MM-DD HH:MM\n..." }
};
await fetch('/v1/environment_providers/private/organizations/{org_id}/environments/{env_id}', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(updated)
});
```

- GET で現在の init_script を読み取り、会話に控える
- 変更は先頭の日時コメント行 `# bump YYYY-MM-DD HH:MM` の追加・更新のみ。他の行に触れない。再構築のトリガーは欄のテキストが変わることなので、同日に複数回 bump しても変化が出るよう時刻まで書く
- POST 前に差分を提示して承認を得る
- POST が失敗したら手動フォールバック: https://claude.ai/code で下部バーの環境タブ（雲アイコン）→ 歯車アイコン → 「Update cloud environment」ダイアログの Setup script 欄を手で書き換える

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

`name`, `description`, `config` が必要。`description` は空文字列でよい。

## エンドポイントの再発見

API が変更されて動かなくなった場合の調査手順。

- Claude in Chrome で https://claude.ai/code を開く
- `read_network_requests` でログをクリアする
- 下部バーの環境タブ（雲アイコン）→ 歯車アイコンでダイアログを開く
- ダイアログを開いた時点の GET リクエストの URL からエンドポイントのパス・org_id・env_id が分かる
- Setup script に何か変更を加えて「Save changes」をクリックする
- `read_network_requests` で POST リクエストの URL を確認する
- `javascript_tool` で同じエンドポイントに GET して、レスポンスのフィールド名を確認する

## 反映範囲

再構築が効くのは bump 後に開始した新規セッションだけ。実行中・再開セッションには効かない。
