#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo '📁 pm'

# https://github.com/nozomiishii/pm
# インストーラは binary を ~/.local/bin、pm.zsh を ~/.config/pm に置く。
# ~/.zshrc への追記は source 行のマーカーがあればスキップされる (home/.zshrc に記載済み)
echo '- 📁 Install pm'
curl -fsSL https://raw.githubusercontent.com/nozomiishii/pm/main/install.sh | bash

# インストーラの導入先 ~/.local/bin は非対話 shell の PATH に無い
export PATH="$HOME/.local/bin:$PATH"

echo "- 📁 pm $(pm --version)"

echo "📁 pm setup is complete 🎉"
