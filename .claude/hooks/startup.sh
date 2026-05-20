#!/usr/bin/env bash
set -euo pipefail
# セッション開始時に worktree を整える（可能なら origin/main 取り込み、必要なら deps install）。

# Claude Code の worktree 作成(EnterWorktree)が共有 .git/config に core.hooksPath を書き込む。
# 値はデフォルト(.git/hooks)と同じで冗長だが、lefthook が「独自パス」とみなし commit ごとの
# self-sync で "Skipping hook sync" 警告を毎回出す。後段の merge --ff-only が走らせる
# post-merge hook より前に unset して打ち消す（--unset-all は未設定だと exit 5 なので保険を付ける）。
# 上流バグ: https://github.com/anthropics/claude-code/issues/27474
git config --unset-all --local core.hooksPath 2>/dev/null || true

git fetch origin --quiet

# 既存の commit や未保存変更を壊さない範囲で HEAD を origin/main まで進める。
# 取り込み時に lock 更新があれば post-merge hook が pnpm install を実行する。
if git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  # merge commit を作らず HEAD を進めるだけ → linear history を維持
  git merge --ff-only origin/main --quiet
fi

if [ ! -d node_modules ]; then
  # fresh worktree 初回など
  pnpm install
fi
