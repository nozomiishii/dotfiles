#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo '👨‍🍳 mise'

# https://mise.jdx.dev/installing-mise.html
echo '- 👨‍🍳 Install mise'
curl -fsSL https://mise.run | sh

# インストーラの導入先 ~/.local/bin は非対話 shell の PATH に無い
export PATH="$HOME/.local/bin:$PATH"

echo "- 👨‍🍳 mise $(mise --version)"

# clone 直後の mise.toml は untrusted なので、task を呼ぶ前に信頼する
echo '- 👨‍🍳 Link dotfiles'
mise trust "$DOTFILES_DIR/mise.toml"
# リンクに repo の [tools] は要らない。ここで入れるとネットワーク待ちが増える
MISE_TASK_RUN_AUTO_INSTALL=0 mise -C "$DOTFILES_DIR" run link

# グローバルツールの導入は mise run toolchains が担う。install.sh では macos.sh の
# 後ろに置き、ツールの取得に失敗しても macOS 設定を巻き添えにしない
echo "👨‍🍳 mise setup is complete 🎉"
