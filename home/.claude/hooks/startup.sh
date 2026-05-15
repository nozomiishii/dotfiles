#!/usr/bin/env bash
# fresh worktree を origin/main に追従させる。
#
# Flow:
#   1. git fetch origin で remote の状態を取り込む
#   2. 自分独自の commit を持ってる？
#      ├─ No  → git merge --ff-only で HEAD を origin/main まで進める
#      │        lock 変化があれば post-merge hook が pnpm install を実行
#      └─ Yes → 何もしない（作業中の commit を守る）
#   3. node_modules が無い？
#      ├─ Yes → pnpm install
#      └─ No  → 何もしない

git fetch origin --quiet || exit 0

if git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  # --ff-only は merge commit を作らず ref を前進させるだけ → linear history を維持
  git merge --ff-only origin/main --quiet
fi

if [ ! -d node_modules ]; then
  pnpm install
fi
