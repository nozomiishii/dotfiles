#!/usr/bin/env bash
set -uo pipefail

# SessionStart hook の stdout がエージェントの context に入るのを防ぐ
exec >&2

mise install
pnpm install
