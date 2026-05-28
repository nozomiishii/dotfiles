#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🤖 Codex'

if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1 && brew list --cask codex >/dev/null 2>&1; then
  echo '- 🤖 Uninstall Homebrew cask codex'
  brew uninstall --cask codex
fi

if ! command -v npm >/dev/null 2>&1; then
  echo '- 🤖 npm is required. Run scripts/toolchains/node.sh first.'
  exit 1
fi

# https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
echo '- 🤖 Install Codex CLI'
npm install -g @openai/codex

echo "- 🤖 codex $(codex --version)"

echo "🤖 Codex setup is complete 🎉"
