#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo '👨‍🍳 mise'

# https://mise.jdx.dev/installing-mise.html
echo '- 👨‍🍳 Install mise'
curl -fsSL https://mise.run | sh

# インストーラの導入先 ~/.local/bin は非対話 shell の PATH に無い
export PATH="$HOME/.local/bin:$PATH"

echo "- 👨‍🍳 mise $(mise --version)"

# グローバルツールは stow 済みの ~/.config/mise/config.toml で宣言する
echo '- 👨‍🍳 Install global tools'
mise install

echo "👨‍🍳 mise setup is complete 🎉"
