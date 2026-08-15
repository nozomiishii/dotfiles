#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🧰 mise'

# https://mise.jdx.dev/installing-mise.html
echo '- 🧰 Install mise'
curl -fsSL https://mise.run | sh

# インストーラの導入先 ~/.local/bin は非対話 shell の PATH に無い
export PATH="$HOME/.local/bin:$PATH"

echo "- 🧰 mise $(mise --version)"

echo "🧰 mise setup is complete 🎉"
