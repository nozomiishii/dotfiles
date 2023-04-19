#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

node_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/msg/msg.sh
source "$node_dir/../../utils/msg/msg.sh"

msg --title '🐉 Node'

echo '- 🐉 Install Node with Volta⚡️'
curl https://get.volta.sh | bash
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

echo "- ⚡️ volta $(volta --version)"

volta install node
volta install yarn@1

echo "- 🐉 node $(node --version)"
echo "- 🚚 yarn $(yarn --version)"

echo '- 🐉 Setup corepack'
yarn global add corepack
corepack enable
corepack enable npm

msg --success "🐉 Node setup is complete 🎉"
