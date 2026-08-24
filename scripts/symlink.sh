#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo -e "🔗 dotfiles link"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# install.sh はこのスクリプトを toolchains/mise.sh より先に呼ぶ
if ! command -v mise > /dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

mise trust ./mise.toml

# --force で repo を正とする
mise bootstrap dotfiles apply --yes --force
