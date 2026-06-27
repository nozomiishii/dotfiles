#!/bin/bash
# Claude Code on the web / Codex Cloud の Setup script 欄に貼る:
#   curl -fsSL https://raw.githubusercontent.com/nozomiishii/dotfiles/main/scripts/cloud/setup.sh | bash
set -euo pipefail

curl -fsSL "https://nozomiishii.github.io/dotfiles/cloud-setup.tar.gz" | tar xz

# Hooks
mkdir -p ~/.hooks
cp home/.hooks/* ~/.hooks/

# Claude Code
mkdir -p ~/.claude
cp home/AGENTS.md ~/.claude/CLAUDE.md
jq 'del(.statusLine, .sandbox)' home/.claude/settings.json >~/.claude/settings.json

# Codex
mkdir -p ~/.codex
cp home/AGENTS.md ~/.codex/AGENTS.md
cp home/.codex/hooks.json ~/.codex/hooks.json

rm -rf home/
