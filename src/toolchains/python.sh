#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

python_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/msg/msg.sh
source "$python_dir/../../utils/msg/msg.sh"

msg --title '🐍 Python'

echo '- 🐍 Install pyenv'
brew install pyenv
echo "- 🐍 $(pyenv --version)"

echo '- 🐍 Install Poetry'
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
echo "- 🐍 $(poetry --version)"

msg --success "🐍 Python setup is complete 🎉"
