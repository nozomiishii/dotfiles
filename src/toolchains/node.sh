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
volta install corepack
volta install yarn@1
volta install pnpm

echo "- 🐉 node $(node --version)"
echo "- 🚚 yarn $(yarn --version)"
echo "- 🎃 pnpm $(pnpm --version)"

echo '- 🐉 Setup corepack'
corepack enable
corepack enable npm

msg --success "🐉 Node setup is complete 🎉"
