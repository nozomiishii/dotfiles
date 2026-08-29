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

# グローバルツールはリンク済みの ~/.config/mise/config.toml で宣言する。
# install.sh ではこの後に macos.sh が控えているため、一時的な失敗で巻き添えに
# しないようリトライする
echo '- 👨‍🍳 Install global tools'
max_attempts="${MISE_INSTALL_MAX_ATTEMPTS:-3}"
attempt=1
backoff_base="${MISE_INSTALL_BACKOFF_SEC:-20}"

while [ "$attempt" -le "$max_attempts" ]; do
  echo "mise install attempt ${attempt}/${max_attempts}"
  if mise install; then
    echo "mise install succeeded"
    break
  fi
  if [ "$attempt" -eq "$max_attempts" ]; then
    echo "mise install failed after ${max_attempts} attempts"
    exit 1
  fi

  sleep "$((backoff_base * attempt))"
  attempt="$((attempt + 1))"
done

echo "👨‍🍳 mise setup is complete 🎉"
