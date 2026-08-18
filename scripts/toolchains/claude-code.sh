#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo '🤖 Claude Code'

# https://docs.anthropic.com/en/docs/claude-code/overview
echo '- 🤖 Install Claude Code'
curl -fsSL https://claude.ai/install.sh | bash

# インストーラの導入先 ~/.local/bin は非対話 shell の PATH に無い
export PATH="$HOME/.local/bin:$PATH"

echo "- 🤖 claude $(claude --version)"

echo "🤖 Claude Code setup is complete 🎉"
