#!/bin/bash
# Claude Code on the web / Codex Cloud の Setup script 欄に貼る:
#   curl -fsSL https://raw.githubusercontent.com/nozomiishii/dotfiles/main/scripts/cloud/setup.sh | bash
set -euo pipefail

raw="https://raw.githubusercontent.com/nozomiishii/dotfiles/main"

# Claude Code
mkdir -p ~/.claude
curl -fsSL "$raw/home/AGENTS.md" -o ~/.claude/CLAUDE.md
curl -fsSL "$raw/home/.claude/settings.json" |
    jq '{permissions: {deny: .permissions.deny}}' \
        >~/.claude/settings.json

# Codex
mkdir -p ~/.codex
curl -fsSL "$raw/home/AGENTS.md" -o ~/.codex/AGENTS.md
