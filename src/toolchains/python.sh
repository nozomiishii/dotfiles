#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e '🐍 Python\n'

echo '- 🐍 Install pyenv'
brew install pyenv
echo "- 🐍 $(pyenv --version)"

echo '- 🐍 Install Poetry'
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
echo "- 🐍 $(poetry --version)"

echo -e "\n${GREEN}🐍 Python setup is complete 🎉${RESET}\n\n"
