---
name: retro
description: >-
  セッションのつまずき・friction を検出し、業務改善につなげる。
  軽い改善はその場で提案、重いものは issue + backlog ノートで管理する。
  ユーザーが /retro と入力したときに使用する。
---

# /retro

会話を振り返り、つまずき・friction を検出して改善につなげる。

## friction の検出

会話全体を振り返り、つまずき・friction の候補を一覧で提示する:

- 問題: 何が起きたか
- 影響: どれくらい手間・時間がかかったか
- 軽重の目安: その場で対応できるか、issue 化が必要か

ユーザーが対応したいものを選ぶ。候補がなければ「特になし」で終了。

## 軽い改善

改善案を提示する。skill 化、CLAUDE.md 追記、memory 書き込みなど。
ユーザーが承認したらその場で対応する。何を対応するかはケースバイケース。

## 重い改善（backlog フロー）

対象 repo への issue 作成と、brain vault への backlog ノート追加を行う。
複数の重い項目は 1 つの PR にまとめる。

### 会話の要約

直前までの議論からタイトル・概要・関連 issue/PR を抽出する。

### 対象 repo の確認

会話内容から対象 repo を推測して提示し、ユーザーに確認する。

### session URL の取得

```sh
F=$(find ~/.claude/projects -name "$CLAUDE_CODE_SESSION_ID.jsonl" | head -1)
grep '"subtype":"bridge_status"' "$F" \
  | grep -oE 'https://claude.ai/code/session_[A-Za-z0-9]+' | tail -1
```

cloud URL は remote-control したセッションにしか記録されない。取れなかった場合はユーザーに知らせて判断を仰ぐ。「URL を貼ってもらう」「URL 無しで進める」などユーザーが選ぶ。黙って placeholder で進めない。黙って中断もしない。

### ドラフト提示と承認

issue 本文と backlog ノート本文をドラフトしてユーザーに提示する。
issue 作成・PR は外向き操作なので、作成前に必ず承認を取る。

- issue / PR タイトル: Conventional Commits（英語）
- issue / PR 本文: 日本語
- session URL は issue / PR 本文に含めない。vault ノートの `## Session` にのみ記載する

### issue の作成

承認後、対象 repo に issue を立て、番号 / URL を控える:

```sh
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の issue 本文。session URL は書かない）
EOF
gh issue create -R <owner/repo> --title "<type>: <subject>" --body-file "$BODY_FILE"
```

### brain vault に worktree を作成

slug はタイトルから英小文字 kebab-case で決める。

```sh
BRAIN="$HOME/Code/nozomiishii/brain"
git -C "$BRAIN" fetch origin main --quiet
git -C "$BRAIN" worktree add "$BRAIN/.claude/worktrees/backlog-<slug>" -b "chore/backlog-<slug>" origin/main
```

### backlog ノートの作成

worktree の `brain/backlog/<slug>.md` に書く。`<today>` は `date +%F` で展開する。

```markdown
---
tags:
  - backlog
created: <today>
status: todo
---

# <タイトル>

## Issue

- [owner/repo#N](URL) — issue タイトル

## Session

- [Claude Code session](<session URL>) — 補足

## 概要

（何をやりたいか・なぜ後回しか）

## 関連

- 関連 issue / PR
```

frontmatter の `status` は todo / doing / done。新規は todo。

session URL が取れなかった場合は `## Session` に「未取得（remote-control 未起動）。後で貼る」と明記する。

### commit / push / PR

```sh
WT="$BRAIN/.claude/worktrees/backlog-<slug>"
git -C "$WT" add "brain/backlog/<slug>.md"
git -C "$WT" commit -m "chore: add <topic> backlog note"
git -C "$WT" push -u origin "chore/backlog-<slug>"
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の PR 本文。refs #<issue> を含める）
EOF
gh pr create -R <brain owner/repo> --base main --head "chore/backlog-<slug>" --title "chore: add <topic> backlog note" --body-file "$BODY_FILE"
```

`gh pr create` には `--head` を必ず付ける。cwd が brain worktree ではないため、付けないと head ブランチの推測に失敗する。

merge はユーザーが手動で行う。AI はマージしない。

## session URL のセキュリティ

session URL は brain vault のノート `## Session` にのみ記載する。
GitHub の issue / PR 本文には絶対に載せない。public / private を問わない。

理由: session URL はデフォルト Private で owner 本人のみ閲覧可。GitHub に貼ると、その issue / PR が public 化した瞬間に会話全文が露出しうる。vault は本人のみがアクセスするローカル環境のため安全。

## Obsidian への反映

ノートを worktree に書いた段階では Obsidian には出ない。PR が main に merge されてから反映される。
