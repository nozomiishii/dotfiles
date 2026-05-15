#!/usr/bin/env bash
# セッション開始時に worktree を整える（可能なら origin/main 取り込み、必要なら deps install）。

git fetch origin --quiet || exit 0

# 自分の commit が無ければ HEAD を origin/main まで進める（あれば作業を守るため触らない）。
# 取り込み時に lock 更新があれば post-merge hook が pnpm install を実行する。
if git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  # merge commit を作らず HEAD を進めるだけ → linear history を維持
  git merge --ff-only origin/main --quiet
fi

if [ ! -d node_modules ]; then
  pnpm install # fresh worktree 初回など
fi
