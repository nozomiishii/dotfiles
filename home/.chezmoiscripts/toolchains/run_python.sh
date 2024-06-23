#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🐍 Python'

echo '- 🐍 Install Rye'
curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash

# shellcheck disable=SC1091
source "$HOME/.rye/env"

echo "- 🐍 $(rye toolchain list)"

echo "🐍 Python setup is complete 🎉"
