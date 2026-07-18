---
name: retro
description: >-
  セッションのつまずき・引っかかりを検出し、業務改善につなげる。
  このセッションでの対応を優先し、issue や spawn_task も選べる。
  ユーザーが /retro と入力したときに使用する。
---

# /retro

会話を振り返り、つまずき・引っかかりを検出して改善につなげる。

## 引っかかりの検出

会話全体を振り返り、つまずき・引っかかりの候補を一覧で提示する:

- 問題: 何が起きたか
- 影響: どれくらい手間・時間がかかったか
- 改善案: skill 化、CLAUDE.md 追記など、会話に即した手段

ユーザーが対応したいものを選ぶ。候補がなければ「特になし」で終了。

## 対応フロー

ユーザーが項目ごとに対応方法を選ぶ。候補の提示時に推奨を添える。

### このセッションで対応

会話のコンテキストを活かしてその場で実装・修正する。CLAUDE.md 追記、skill の修正、設定変更など。

### spawn_task

会話コンテキストが不要な項目、またはコンテキストが逼迫しているときに使う。spawn_task のプロンプトにはファイルパスと十分な背景を含め、この会話なしで単独実行できるようにする。

### issue

調査や設計が必要で今すぐ着手できない項目。

#### 会話の要約

直前までの議論からタイトル・概要・関連 issue/PR を抽出する。

#### 対象 repo の確認

会話内容から対象 repo を推測して提示し、ユーザーに確認する。

#### ドラフト提示と承認

issue 本文をドラフトしてユーザーに提示する。
issue 作成は外向き操作なので、作成前に必ず承認を取る。

- issue タイトル: Conventional Commits（英語）
- issue 本文: 日本語
- セッション内容は要約して本文に書く

#### issue の作成

承認後、対象 repo に issue を立てる:

```sh
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の issue 本文。session URL は書かない）
EOF
gh issue create -R <owner/repo> --title "<type>: <subject>" --body-file "$BODY_FILE"
```

## session URL のセキュリティ

session URL は GitHub の issue / PR 本文に絶対に載せない。public / private を問わない。

理由: session URL はデフォルト Private で owner 本人のみ閲覧可。GitHub に貼ると、その issue / PR が public 化した瞬間に会話全文が露出しうる。セッション内容は要約して本文に書く。
