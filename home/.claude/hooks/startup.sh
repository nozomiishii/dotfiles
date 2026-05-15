#!/usr/bin/env bash
set -euo pipefail
# セッション開始時に worktree を整える（可能なら origin/main 取り込み、必要なら deps install）。

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
