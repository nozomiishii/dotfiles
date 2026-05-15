#!/usr/bin/env bash
# セッション開始時に worktree を整える（可能なら origin/main 取り込み、必要なら deps install）。
#
# Flow:
#   1. git fetch origin で remote の状態を取り込む
#   2. 自分独自の commit を持ってる？
#      ├─ No  → git merge --ff-only で HEAD を origin/main まで進める
#      │        lock 変化があれば post-merge hook が pnpm install を実行
#      └─ Yes → 何もしない（作業中の commit を守る）
#   3. node_modules が無い？
#      ├─ Yes → pnpm install（fresh worktree 初回など）
#      └─ No  → 何もしない

git fetch origin --quiet || exit 0

if git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
  # --ff-only は merge commit を作らず ref を前進させるだけ → linear history を維持
  git merge --ff-only origin/main --quiet
fi

if [ ! -d node_modules ]; then
  pnpm install
fi
