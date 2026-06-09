#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🤖 Codex'

# https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
echo '- 🤖 Install Codex CLI'
npm install -g @openai/codex

echo "- 🤖 codex $(codex --version)"

echo '- 🤖 Install Codex plugins'
SUPERPOWERS_MARKETPLACE_DIR="$HOME/.codex/plugins/superpowers-marketplace"
SUPERPOWERS_PLUGIN_DIR="$SUPERPOWERS_MARKETPLACE_DIR/plugins/superpowers"
mkdir -p "$SUPERPOWERS_MARKETPLACE_DIR/plugins" "$SUPERPOWERS_MARKETPLACE_DIR/.agents/plugins"

if [ -d "$SUPERPOWERS_PLUGIN_DIR/.git" ]; then
  git -C "$SUPERPOWERS_PLUGIN_DIR" pull --ff-only
elif [ ! -e "$SUPERPOWERS_PLUGIN_DIR" ]; then
  git clone --depth 1 https://github.com/obra/superpowers.git "$SUPERPOWERS_PLUGIN_DIR"
fi

cat >| "$SUPERPOWERS_MARKETPLACE_DIR/.agents/plugins/marketplace.json" <<'JSON'
{
  "name": "superpowers-local",
  "plugins": [
    {
      "name": "superpowers",
      "source": {
        "source": "local",
        "path": "./plugins/superpowers"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
        "products": ["CODEX"]
      },
      "category": "Developer Tools"
    }
  ]
}
JSON

codex plugin marketplace add "$SUPERPOWERS_MARKETPLACE_DIR"
codex plugin add superpowers@superpowers-local

echo "🤖 Codex setup is complete 🎉"
