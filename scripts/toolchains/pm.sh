#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
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
