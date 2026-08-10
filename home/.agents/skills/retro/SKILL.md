---
name: retro
description: >-
  セッションのつまずき・引っかかりを検出し、業務改善につなげる。
  このセッションでの対応を優先し、issue や新しいタスクへの切り出しも選べる。
  「うまくいかなかったところを直したい」「今回詰まった点を整理したい」と言ったときに使用する。
---

# /retro

会話を振り返り、つまずき・引っかかりを検出して改善につなげる。

## 引っかかりの検出

会話全体を振り返り、つまずき・引っかかりの候補を一覧で提示する:

- 問題: 何が起きたか
- 影響: どれくらい手間・時間がかかったか
- 改善案: skill 化、AGENTS.md 追記など、会話に即した手段

ユーザーが対応したいものを選ぶ。候補がなければ「特になし」で終了。

## 対応フロー

ユーザーが項目ごとに対応方法を選ぶ。候補の提示時に推奨を添える。

### このセッションで対応

会話のコンテキストを活かしてその場で実装・修正する。AGENTS.md 追記、skill の修正、設定変更など。AGENTS.md を変更するときは sibling の [doc SKILL.md](../doc/SKILL.md) を明示的に読み、その判定と文章ガイドラインに従う。Claude Code を使う repo では CLAUDE.md の bridge も必ず確認する。

### 新しいタスクへ切り出す

会話コンテキストが不要な項目、またはコンテキストが逼迫しているときに使う。ユーザーがこの方法を選んだら、Claude Code デスクトップでは `spawn_task`、Codex App では新しいタスクを作る機能を使う。CLI では sibling の [wt SKILL.md](../wt/SKILL.md) を明示的に読み、worktree を用意する。Claude Code は `claude --bg`、Codex は `codex exec --sandbox workspace-write -C` で実行する。プロンプトにはファイルパスと十分な背景を含め、この会話なしで単独実行できるようにする。

### issue

調査や設計が必要で今すぐ着手できない項目。

#### 会話の要約

直前までの議論からタイトル・概要・関連 issue/PR を抽出する。

#### 対象 repo の確認

会話内容から対象 repo を推測して提示し、ユーザーに確認する。

#### ドラフト提示と承認

issue 本文をドラフトしてユーザーに提示する。
issue 作成は外向き操作なので、作成前に必ず承認を取る。

- issue タイトル: 内容を表す日本語。Conventional Commits 形式 (`feat:` 等の type prefix) は使わない。一覧で PR と見分けがつかなくなるため
- issue 本文: 日本語
- セッション内容は要約して本文に書く

#### issue の作成

承認後、対象 repo に issue を立てる:

```sh
TITLE_FILE=$(mktemp)
BODY_FILE=$(mktemp)
cat > "$TITLE_FILE" <<'RETRO_TITLE_7D8A4F'
<内容を表す日本語タイトル>
RETRO_TITLE_7D8A4F
cat > "$BODY_FILE" <<'RETRO_BODY_C2E91B'
（日本語の issue 本文。session URL は書かない）
RETRO_BODY_C2E91B
IFS= read -r TITLE < "$TITLE_FILE"
gh issue create -R <owner/repo> --title "$TITLE" --body-file "$BODY_FILE"
```

タイトルも本文もクォート付き heredoc へ書き、shell のコードではなくデータとして渡す。heredoc delimiter はタイトル用と本文用で分け、承認済み内容に同じ standalone line が無い文字列を選ぶ。衝突する場合は command を実行する前に別の delimiter へ変える。タイトルファイルが空でない 1 行だけであることを確認してから `gh` を呼ぶ。承認済みタイトルを command へ直接埋め込まない。

## session URL のセキュリティ

session URL は GitHub の issue / PR 本文に絶対に載せない。public / private を問わない。

理由: session URL はデフォルト Private で owner 本人のみ閲覧可。GitHub に貼ると、その issue / PR が public 化した瞬間に会話全文が露出しうる。セッション内容は要約して本文に書く。
