#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

node_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/msg/msg.sh
source "$node_dir/../../utils/msg/msg.sh"

msg --title '🐉 Node'

echo '- 🐉 Install Node with Volta⚡️'
curl https://get.volta.sh | bash
export VOLTA_HOME="$HOME/.volta"
export VOLTA_FEATURE_PNPM=1
export PATH="$VOLTA_HOME/bin:$PATH"

echo "- ⚡️ volta $(volta --version)"
volta install node
echo "- 🐉 node $(node --version)"

echo '- 🐉 Setup corepack'
volta install corepack
# https://github.com/volta-cli/volta/issues/987
# npm install -g corepack
corepack enable pnpm yarn npm --install-directory ~/.volta/bin

# corepack enable pnpm yarn npm
echo '- 🐉 Setup package Managers'

volta install npm
volta install pnpm
volta install yarn@1

corepack prepare npm@latest --activate
corepack prepare pnpm@latest --activate
corepack prepare yarn@1.22.19 --activate

volta list

echo '- 🐉 Setup npm global'
volta install typescript

msg --success "🐉 Node setup is complete 🎉"
