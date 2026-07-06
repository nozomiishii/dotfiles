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

# direnv (apply-direnv.sh hook が .envrc を評価するのに必要)
if ! command -v direnv >/dev/null 2>&1; then
  bin_path=/usr/local/bin
  [ -w "$bin_path" ] || {
    bin_path="$HOME/.local/bin"
    mkdir -p "$bin_path"
  }
  curl -fsSL https://direnv.net/install.sh | bin_path="$bin_path" bash
fi

# direnv whitelist。cloud の checkout 配下だけを信頼する (作業中に clone した
# 外部 repo の .envrc まで実行しないための信頼ゲート)。
mkdir -p ~/.config/direnv
cat >~/.config/direnv/direnv.toml <<EOF
[whitelist]
prefix = ["$PWD"]
EOF

rm -rf home/
