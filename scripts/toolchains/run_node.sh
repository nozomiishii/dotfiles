#!/bin/bash

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

echo '- 🐉 Setup npm global'
npm i -g @devcontainers/cli
npm i -g typescript
npm i -g @anthropic-ai/claude-code

echo "🐉 Node setup is complete 🎉"
