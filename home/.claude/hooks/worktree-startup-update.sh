#!/usr/bin/env bash
# fresh worktree を origin/main に追従させる (分岐していたら何もしない)。

git fetch origin --quiet || exit 0
git merge --ff-only origin/main --quiet 2>/dev/null || true

# node_modules 不在 = fresh worktree (lefthook が走らなかったケースの保険)
if [ ! -d node_modules ]; then
  pnpm install
fi
