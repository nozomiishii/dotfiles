#!/usr/bin/env bash
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -z "$root" ]; then
  exit 0
fi
cd "$root" || exit 0

if [ ! -d node_modules ]; then
  pnpm install
fi

exit 0
