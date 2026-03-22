#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🐉 Node'

# https://github.com/Schniz/fnm
echo '- 🐉 Install Node with fnm🚀'

brew install fnm
eval "$(fnm env)"

echo "- ⚡️ fnm $(fnm --version)"
fnm install --lts
echo "- 🐉 node $(node --version)"

echo '- 🐉 Setup corepack'
corepack enable pnpm yarn npm

echo '- 🐉 Install Bun'
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
echo "- 🐉 bun $(bun --version)"

echo '- 🐉 Setup pnpm global'
(
    cd /tmp
    npm install -g @devcontainers/cli
    npm install -g typescript
    npm install -g @github/copilot
    npm install -g @antfu/ni
)

echo "🐉 Node setup is complete 🎉"
