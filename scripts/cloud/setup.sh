#!/bin/bash
# Claude Code on the web / Codex Cloud の Setup script 欄に貼る:
#   curl -fsSL https://raw.githubusercontent.com/nozomiishii/dotfiles/main/scripts/cloud/setup.sh | bash
set -euo pipefail

curl -fsSL "https://nozomiishii.github.io/dotfiles/cloud-setup.tar.gz" | tar xz

# Claude Code
mkdir -p ~/.claude
jq 'del(.statusLine, .sandbox)' home/.claude/settings.json >~/.claude/settings.json

# Codex
mkdir -p ~/.codex
cp home/AGENTS.md ~/.codex/AGENTS.md

# Agents (skills)
mkdir -p ~/.agents ~/.claude/skills
cp -R home/.agents/. ~/.agents/
cp -R home/.agents/skills/. ~/.claude/skills/

# mise
if ! command -v mise >/dev/null 2>&1; then
  tag=$(curl -fsSLo /dev/null -w '%{url_effective}' https://github.com/jdx/mise/releases/latest)
  tag=${tag##*/}
  curl -fsSLo /usr/local/bin/mise "https://github.com/jdx/mise/releases/download/$tag/mise-$tag-linux-x64"
  chmod +x /usr/local/bin/mise
fi

rm -rf home/
