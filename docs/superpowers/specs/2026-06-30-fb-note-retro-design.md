# /fb・/note・/retro 設計

セッション終了時の振り返りを 3 つの skill に分解する。

## skill 構成

### /note — 知識ノート作成

会話で学んだことをトピック単位で brain vault に保存する。

- 会話を振り返り、学んだトピックの候補を一覧提示
- ユーザーが選んだものごとに Zettelkasten 形式のノートを作成
- brain vault に worktree → `brain/main/<slug>.md` → commit → push → PR
- 候補がなければ「特になし」で終了

### /retro — 業務改善

つまずいたワークフローを検出し、改善につなげる。`/backlog` の後継。

- 会話を振り返り、つまずき・friction の候補を一覧提示
- ユーザーが選んだものについて軽重を判断
  - 軽いもの → 改善案を提示、ユーザー判断でその場対応
  - 重いもの → backlog フロー（issue + brain vault `brain/backlog/<slug>.md` + PR）
- 候補がなければ「特になし」で終了

### /fb — 振り返りオーケストレーター

`/note` → `/retro` を順に実行する。

- Phase 1 で `/note` を実行
- Phase 2 で `/retro` を実行
- どちらもスキップ可能

### /backlog — 廃止

`/retro` に吸収。skill ファイルを削除する。

## 知識ノートのスキーマ

`brain/main/<slug>.md`:

```markdown
---
tags:
  - <内容に合ったタグ>
created: <today>
---

# <トピック名>

（1 つの概念・知識を自己完結的に説明する。
関連する概念は [[wiki-link]] でつなぐ。
コード例・図は必要に応じて含める。
そのままブログに公開しても問題ない品質。）
```

- タグは内容に応じて適切なものを付ける（`git`, `typescript`, `shell` 等）
- session URL や出自情報は含めない
- 見出し構造はトピックに応じて自然に
- 既存の brain vault のノートと `[[wiki-link]]` でつながる

## backlog ノートのスキーマ

`brain/backlog/<slug>.md`（既存の backlog skill から引き継ぐ）:

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

## 共通の操作パターン

### session URL 取得

```sh
F=$(find ~/.claude/projects -name "$CLAUDE_CODE_SESSION_ID.jsonl" | head -1)
grep '"subtype":"bridge_status"' "$F" \
  | grep -oE 'https://claude.ai/code/session_[A-Za-z0-9]+' | tail -1
```

取れなかった場合はユーザーに知らせて判断を仰ぐ。

### brain vault 操作

- canonical パス: `BRAIN="$HOME/Code/nozomiishii/brain"`
- worktree は `$BRAIN/.claude/worktrees/<slug>` に作成
- `git -C "$BRAIN" fetch origin main --quiet && git -C "$BRAIN" worktree add "$BRAIN/.claude/worktrees/<slug>" -b "<branch>" origin/main`
- `gh pr create` には `--head` を必ず付ける

### session URL のセキュリティ

- session URL は brain vault のノートにのみ記載する（backlog ノートの `## Session`）
- GitHub の issue / PR 本文には絶対に載せない（public / private 問わず）
- 知識ノートには session URL を含めない（公開可能な品質を保つため）

### issue / PR の規約

- issue / PR タイトル: Conventional Commits（英語）
- issue / PR 本文: 日本語
- merge はユーザーが手動で行う。AI はマージしない

## /note の詳細フロー

- 会話を振り返り、学んだトピックを抽出
- 候補をリストで提示（トピック名 + 1行サマリー）
- ユーザーが保存したいものを選ぶ
- brain vault に worktree を切る
- 選ばれたトピックごとに `brain/main/<slug>.md` にノート作成
  - slug はトピック名から英小文字 kebab-case
- commit → push → PR
- 複数ノートは 1 つの PR にまとめる

## /retro の詳細フロー

- 会話を振り返り、つまずき・friction を抽出
- 候補をリストで提示（問題 + 影響 + 軽重の目安）
- ユーザーが対応したいものを選ぶ
- 軽いもの:
  - 改善案を提示（skill 化、CLAUDE.md 追記、memory 書き込み等）
  - ユーザーが承認したらその場で対応
- 重いもの:
  - 対象 repo を推測して提示、ユーザーに確認
  - issue を作成
  - brain vault に worktree を切る
  - `brain/backlog/<slug>.md` にノート作成
  - commit → push → PR
- 複数の重い項目は 1 つの PR にまとめる（backlog ノートが複数入る）

## /fb の詳細フロー

- Phase 1: `/note` skill を実行
- Phase 2: `/retro` skill を実行
- 各 phase の結果（PR URL 等）を最後にまとめて報告
