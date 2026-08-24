#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo -e "🔗 dotfiles link"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# install.sh の初回実行時点では mise が未導入なので、ここで入れる
# (toolchains/mise.sh と同じ https://mise.run 経路。導入済みなら何もしない)
if ! command -v mise > /dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# [dotfiles] を含む repo config を明示的に信頼する (新規マシンと mise.toml 更新後の再確認を無人化)
mise trust ./mise.toml

# repo を常に正とする。衝突する実ファイルは --force で repo へのリンクに置き換える
# (旧 stow --adopt + git restore と同じ結果)。source 削除で宙吊りになったリンクの
# 掃除も apply が state を見て行う
mise bootstrap dotfiles apply --yes --force
