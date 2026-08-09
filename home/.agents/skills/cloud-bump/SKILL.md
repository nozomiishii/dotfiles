---
name: cloud-bump
description: >-
  claude.ai の cloud 環境の init_script を内部 API で更新し、
  環境スナップショットの再構築を発火させる。
  dotfiles の main にマージした変更が
  cloud 配信対象 (cloud-setup.yaml の paths) に触れていたときに使用する。
  dotfiles を変更する PR を作成するときも、マージ後の bump の要否判定と予告のために使用する。
model: sonnet
allowed-tools: mcp__claude-in-chrome__javascript_tool
---

# /cloud-bump

cloud 環境の setup script は毎セッション走らない。再構築のトリガーは Setup script 欄の変更・allowed network hosts の変更・約 7 日のキャッシュ失効だけで ([Environment caching](https://code.claude.com/docs/en/claude-code-on-the-web#environment-caching))、main にマージしても bump しない限り新規セッションは最大 7 日前のスナップショットで起動する。「マージされたので自動で反映済み」は誤り。

## 発火の判定

- 判定リストの正本は `.github/workflows/cloud-setup.yaml` の `paths`。スキルに書き写さず、workflow ファイルを読んで diff と突き合わせる。触れていなければ bump 不要と伝えて終わる
- bump してよいのは main にマージ済みの変更だけ。マージ前に bump すると古い main でスナップショットが焼き直されるだけになる
- cloud 配信対象に触れる PR を作成した時点では bump せず、マージ後に /cloud-bump の実行が必要なことを PR 作成の報告に書いて予告する
- ユーザーが bump を明示的に依頼した場合もこの判定を省略しない。判定を終える前に「手順」へ進まない

## 権限

- Claude Code: JS 実行の許可は frontmatter の allowed-tools で与える。settings.json に javascript_tool の常時 allow を置かない。許可はこのスキルを起動したターンだけ有効で、次のユーザーメッセージで消える ([skills.md](https://code.claude.com/docs/en/skills.md))。承認待ちでターンをまたいだら、POST の前にスキルを起動し直して許可を再適用する
- Codex: 最初に `$chrome:control-chrome` を読み、既存の Chrome セッションを選ぶ。本文と scripts/ の JavaScript を literal なツール名として呼ばず、browser-client の Playwright 評価・ネットワーク観察・クリックへ読み替える。最初に、page origin への GET と POST、ネットワーク観察を実行できる capability があるか確認する。capability が欠けていれば API 操作を試さず停止し、「手順」末尾の手動フォールバック URL を案内する。承認でターンをまたいだら `$cloud-bump` を再度読み、Chrome 接続と GET 結果を再確認してから POST する

## 承認

どちらの環境でも POST 前の差分承認を省略しない。`claude.ai/code` を開いた tab ID と bootstrap URL を最初に固定し、全 read、network 観察、fetch、click の直前に、固定した tab ID・`https://claude.ai` origin・`/code` で始まる path が一致することを確認する。不一致なら環境設定を送受信せず停止する。

Claude Code で承認を求めるときは、環境名・snapshot digest・現在の bump 行・proposedBumpLine を提示した上で、AskUserQuestion で「承認して POST する」「キャンセル」の選択肢を出す。テキスト返信を待つ承認にしない。差分を質問文にも直前のメッセージにも示さないまま選択肢だけを出さない。「承認して POST する」が選ばれたときだけ POST に進む。回答は同一ターンに返るため allowed-tools の許可は有効のまま使える。回答が得られないままターンをまたいだ場合は、「権限」の規則どおりスキルを起動し直して許可を再適用し、承認後の fresh GET の digest 照合を経てから POST する。

Codex で承認を求めるときは、ユーザーへ「`$cloud-bump 承認` と返信してください」と案内して turn を終える。次の発話で skill を明示的に再起動し、Chrome 接続と GET 結果が承認前と一致することを確認してから POST する。単なる「承認します」という返信を、skill を再読せずに処理しない。

## 手順

claude.ai の未文書化 API を使う。エンドポイント・レスポンス構造・POST 必須フィールド・動かなくなったときの再発見手順は [references/api.md](references/api.md) を読む。

1. Claude in Chrome で <https://claude.ai/code> を開く
2. [scripts/get-env-summary.js](scripts/get-env-summary.js) を読み、`<network-log-derived-org-id>` と `<network-log-derived-env-id>` を実値に置換した文字列を javascript_tool で実行する。ファイル自体は書き換えない。環境が複数あるときは、どれを bump するかユーザーに確認する
3. 返った `snapshotDigest`・環境名・現在の bump 行・`proposedBumpLine` だけを会話に控え、「承認」の作法で差分承認を得る。env 全体や `config.environment` を会話へ出さない
4. 承認後、[scripts/post-bump.js](scripts/post-bump.js) を読み、`<approved-snapshot-sha256>` と `<approved-bump-line>` を承認済みの実値に置換した文字列を、別の JavaScript call として実行する。script が fresh GET の digest 照合・bump 行だけの書き換え検証・POST・検証 GET まで自己完結する。前の call の lexical binding は使わない
5. POST が失敗したら手動フォールバック: <https://claude.ai/code> で下部バーの環境タブ（雲アイコン）→ 歯車アイコン → 「Update cloud environment」ダイアログの Setup script 欄を手で書き換える

init_script が非 0 で終了する状態になると新規セッションが全て起動不能になる。欄を壊さないことを何より優先する。

## 反映範囲

再構築が効くのは bump 後に開始した新規セッションだけ。実行中・再開セッションには効かない。

## 経緯

設計判断を調べるときだけ参照する。設計の経緯は [dotfiles#1347](https://github.com/nozomiishii/dotfiles/issues/1347)。
