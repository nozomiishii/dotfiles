#!/usr/bin/env bash
#
# check-skills-sync.sh - Verify skill symlinks are in sync
#
# For each skill in home/.config/skills/<name>/, checks that the
# corresponding symlinks exist at $HOME for Cursor, Claude Code, and Codex.
#
# Usage:
#   bash scripts/check-skills-sync.sh           # local / lefthook
#   bash scripts/check-skills-sync.sh --repo    # CI (checks repo directory instead of $HOME)
#
set -euo pipefail

if [ "${1:-}" = "--repo" ]; then
  SKILLS_DIR="home/.config/skills"
  TARGET_BASE="home"
else
  SKILLS_DIR="$HOME/.config/skills"
  TARGET_BASE="$HOME"
fi

if [ ! -d "$SKILLS_DIR" ]; then
  exit 0
fi

errors=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")

  for target in \
    "$TARGET_BASE/.cursor/skills/$name" \
    "$TARGET_BASE/.codex/skills/$name" \
    "$TARGET_BASE/.claude/commands/$name.md"; do
    if [ ! -e "$target" ]; then
      echo "ERROR: missing skill link: $target"
      errors=$((errors + 1))
    fi
  done
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Run 'make link' to fix missing skill symlinks."
  exit 1
fi
