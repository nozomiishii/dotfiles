#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e '🐉 Node\n'

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

echo -e "\n${GREEN}🐉 Node setup is complete 🎉${RESET}\n\n"
