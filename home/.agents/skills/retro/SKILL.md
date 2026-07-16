---
name: retro
description: >-
  セッションのつまずき・引っかかりを検出し、業務改善につなげる。
  改善は対象 repo の issue で管理する。
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

## issue フロー

選ばれた改善は対象 repo への issue 作成で管理する。

### 会話の要約

直前までの議論からタイトル・概要・関連 issue/PR を抽出する。

### 対象 repo の確認

会話内容から対象 repo を推測して提示し、ユーザーに確認する。

### ドラフト提示と承認

issue 本文をドラフトしてユーザーに提示する。
issue 作成は外向き操作なので、作成前に必ず承認を取る。

- issue タイトル: Conventional Commits（英語）
- issue 本文: 日本語
- セッション内容は要約して本文に書く

### issue の作成

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
