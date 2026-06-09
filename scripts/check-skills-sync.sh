#!/usr/bin/env bash
#
# check-skills-sync.sh - Verify skill layout and installed Claude symlinks
#
# Repository mode checks the source layout under home/.agents/skills.
# Local mode checks that make link has installed Claude Code symlinks.
#
# Usage:
#   bash scripts/check-skills-sync.sh           # local
#   bash scripts/check-skills-sync.sh --repo    # lefthook / CI
#
set -euo pipefail

if [ "${1:-}" = "--repo" ]; then
  SKILLS_DIR="home/.agents/skills"
  TARGET_BASE="home"
  check_targets=false
else
  SKILLS_DIR="$HOME/.agents/skills"
  TARGET_BASE="$HOME"
  check_targets=true
fi

if [ ! -d "$SKILLS_DIR" ]; then
  exit 0
fi

errors=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  name=$(basename "$skill_dir")

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "ERROR: missing skill file: $skill_dir/SKILL.md"
    errors=$((errors + 1))
  fi

  if [ "$check_targets" = false ]; then
    continue
  fi

  for target in "$TARGET_BASE/.claude/skills/$name"; do
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
