#!/bin/bash
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
