---
name: cloud-bump
description: >-
  claude.ai の cloud 環境の Setup script 欄の日時コメントを Claude in Chrome で更新し、
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

## 欄の書き換え (Claude in Chrome)

https://claude.ai/code を開き、対象環境の設定ダイアログの Setup script 欄を編集する。環境が複数あるときは、どれを bump するかユーザーに確認する。

- 編集前に欄の現在値を読み取り、会話に控える
- 変更は先頭の日時コメント行 `# bump YYYY-MM-DD HH:MM` の追加・更新のみ。他の行に触れない。再構築のトリガーは欄のテキストが変わることなので、同日に複数回 bump しても変化が出るよう時刻まで書く
- 保存前に差分を提示して承認を得る
- 操作に失敗したらリトライで粘らず、手動手順を案内して止まる: https://claude.ai/code で対象環境の設定を開き、日時コメントを手で書き換える

Setup script が非 0 で終了する状態になると新規セッションが全て起動不能になる。欄を壊さないことを何より優先する。

## 反映範囲

再構築が効くのは bump 後に開始した新規セッションだけ。実行中・再開セッションには効かない。
