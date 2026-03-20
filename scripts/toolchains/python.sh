#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🐍 Python'

# uv
# https://docs.astral.sh/uv/getting-started/installation/
echo '- 🐍 Install uv'

curl -LsSf https://astral.sh/uv/install.sh | sh

echo "- 🐍 uv: $(uv self version)"

echo "🐍 Python setup is complete 🎉"
