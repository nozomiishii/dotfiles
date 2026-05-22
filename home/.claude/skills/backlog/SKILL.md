---
name: backlog
description: >-
  「あとでやりたいこと」を、検討ログ（Claude Code session URL）と成果物（GitHub issue / PR）と
  一緒に 1 ノートにまとめて brain vault の backlog に保存する。
  ユーザーが /backlog と入力したとき、または「バックログに積んで」「あとでやるやつ保存して」
  「backlog に残して」と言ったときに使用する。
argument-hint: バックログのタイトル / 補足（任意）
---

# /backlog

いま進行中の会話を「あとでやる」backlog ノートに束ねる。直前までの議論を要約し、

1. 対象 repo に GitHub **issue** を立て、
2. brain vault の `brain/backlog/<slug>.md` に **session URL + issue** を貼ったノートを追加して **PR** を出す。

着手時に「タスク → 議論の経緯 → issue/PR」を逆引きできる導線を作るのが目的。

## 前提

- ネタ元は **直前までの会話の要約**。会話が薄いときだけ、最小限の対話で概要・タイトルを補う。
- brain vault の canonical パス（Obsidian が見ている実体 / git の main checkout）:
  `BRAIN="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"`
  （ユーザー名はハードコードせず `$HOME` を使う）
- backlog ノートのスキーマは brain repo の `CLAUDE.md`（backlog/ の運用）に従う。

## 手順

### 1. 会話を要約

直前までの議論から **タイトル**・**概要（数行）**・**関連 issue / PR** を抽出する。引数があればタイトル / 補足の手がかりとして使う。

### 2. issue の対象 repo を決める

会話内容から対象 repo を**推測して提示**し、ユーザーに確認する。外したらユーザーに指定してもらう。

- ネタ自体が brain vault の話なら、issue も **brain repo** に立てる（= ノートと同じ repo になる）。

### 3. session URL を取得

現セッションの cloud URL を `bridge_status` イベントから抽出する:

```sh
F=$(find ~/.claude/projects -name "$CLAUDE_CODE_SESSION_ID.jsonl" | head -1)
grep '"subtype":"bridge_status"' "$F" \
  | grep -oE 'https://claude.ai/code/session_[A-Za-z0-9]+' | tail -1
```

cloud URL は remote-control（web から開く / `claude --remote-control` / `/remote-control`）したセッションにしか記録されない。**取れなかったら一度ユーザーに知らせて判断を仰ぐ**（黙って placeholder で進めない / 黙って中断もしない）。「URL を貼ってもらう」「URL 無しで進める」などをユーザーが選ぶ。

### 4. issue 本文とノート本文をドラフトしてユーザーに提示

issue 作成・PR は外向き操作なので、**作成前に必ずドラフトを見せて承認を取る**。

- issue / PR タイトル: Conventional Commits（英語）`<type>: <subject>`（scope は付けない）。
- issue / PR 本文: 日本語。

### 5. issue を作成

承認後、対象 repo に issue を立て、番号 / URL を控える:

```sh
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の issue 本文）
EOF
gh issue create -R <owner/repo> --title "<EN conventional commits>" --body-file "$BODY_FILE"
```

### 6. brain repo に worktree を切る

slug を決める（タイトルから英小文字 kebab-case。例: `feature-flag-release-flow`）。canonical の **main 基点**で worktree を作る（`.claude/worktrees/` は brain の規約・gitignore 済み）:

```sh
git -C "$BRAIN" fetch origin main --quiet
git -C "$BRAIN" worktree add "$BRAIN/.claude/worktrees/<slug>" -b "chore/backlog-<slug>" origin/main
```

### 7. ノートを書き出す

worktree の `brain/backlog/<slug>.md` に、`<today>` を実際の日付（`date +%F`）に展開して書く:

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

- [Claude Code session](<session URL>) — 補足（Private session / private repo など）

## 概要

（数行で、何をやりたいか・なぜ後回しか）

## 関連

- 関連 issue / PR
```

- session URL が取れなかった場合は、`## Session` に「未取得（remote-control 未起動）。後で貼る」と明記し、ユーザーが後から追記できる形にする。

### 8. commit → push → PR

brain repo 向けに PR を出す（base main）。本文に `refs #<issue>` で issue を紐付ける:

```sh
WT="$BRAIN/.claude/worktrees/<slug>"
git -C "$WT" add "brain/backlog/<slug>.md"
git -C "$WT" commit -m "chore: add <topic> backlog note"
git -C "$WT" push -u origin "chore/backlog-<slug>"
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の PR 本文。refs #<issue> を含める）
EOF
gh pr create -R <brain owner/repo> --base main --title "chore: add <topic> backlog note" --body-file "$BODY_FILE"
```

- **merge は必ずユーザーが手動で行う**。AI はマージしない。

## 注意

- session URL を public な GitHub リポジトリや公開ページに生で貼らない（brain vault はローカル + iCloud で本人のみアクセスのため OK）。issue / PR 本文には URL でなく要約を書く。
- ノートを worktree に書いた段階では Obsidian（canonical を見ている）にはまだ出ない。PR が main に merge されてから反映される。
