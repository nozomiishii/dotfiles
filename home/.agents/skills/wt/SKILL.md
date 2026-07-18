---
name: wt
description: >-
  repo をまたぐタスクの切り出し方、セッションの作り直し方、git worktree を用意する手順。
  ユーザーが /wt と入力したとき、セッション開始ディレクトリ以外の repo を変更するとき、
  コンテキストが増えたセッションを作り直したいと言ったとき、
  またはスキルや作業フローが作業用 worktree を必要とするときに使用する。
---

# /wt

repo をまたぐタスクは、同一セッションで worktree を切るよりセッションごと分けるのが基本。新セッションの worktree は Claude Code 本体が最新 origin/HEAD 起点で作り、repo の SessionStart hook (`.claude/settings.json` → `.hooks/setup.sh`) が依存 install まで整える。設計の経緯は [dotfiles#1268](https://github.com/nozomiishii/dotfiles/issues/1268)。

- デスクトップ: 対象 repo の新セッションとして切り出す (spawn_task)
- CLI: `(cd "$REPO" && claude --bg "<タスク>")`
- 会話の流れ上、同一セッションで続けるときだけ下の手順で worktree を切る

## 同一 repo でセッションを作り直す

コンテキストが増えたセッションを畳んで続きを新セッションでやるときも、セッションごと分ける方針は同じ。

- 作業途中の変更は commit して push してから畳む。未コミットのまま引き継ぐ案内をしない。worktree の削除プロンプトや自動 cleanup で作業ごと消える
- 続きは同じブランチ・同じ worktree を開き直す: デスクトップは worktree 選択で既存を選ぶ、CLI は `claude --worktree <名前>` (名前の再利用で同じ worktree が開く)
- 背景・残作業・ブランチ名は新セッションの最初のメッセージに書いて渡す

## 同一セッションで worktree を切る

REPO は対象 repo のルート。SLUG はブランチ名で、呼び出し元の規約に従う (無ければ作業内容の kebab-case)。

```sh
git -C "$REPO" fetch origin main --quiet
WT="$REPO/.claude/worktrees/$SLUG"
git -C "$REPO" worktree add "$WT" -b "$SLUG" origin/main
[ -f "$WT/.hooks/setup.sh" ] && (cd "$WT" && bash .hooks/setup.sh)
```

- setup.sh が worktree の依存 install を行う。worktree の作成では repo の SessionStart hook が発火しないため、作成直後の明示実行が必須。これを飛ばすと lefthook 等が黙って壊れたまま気づけない
- .envrc のある repo で env に依存するコマンドは `direnv exec "$WT" <コマンド>` で実行する。clone 先が direnv の whitelist 外の場合は先に `direnv allow "$WT"` を実行する
- REPO が無い cloud セッションでは、AGENTS.md の「cloud セッション」規約で repo を用意し、clone 先を REPO とする
- 後続の commit / push / PR の規約は呼び出し元 (スキルや会話) に従う
