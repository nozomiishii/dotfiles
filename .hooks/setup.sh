#!/usr/bin/env bash
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -z "$root" ]; then
  exit 0
fi
cd "$root" || exit 0

# commit 時の lefthook 等が node_modules/.bin を呼ぶため。
if [ ! -d node_modules ]; then
  pnpm install
fi

exit 0
