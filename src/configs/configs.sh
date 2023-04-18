#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "🧝🏻‍♀️ Starting Configs setup...\n\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/../../utils/create_symlinks/create_symlinks.sh"

create_symlinks --source "$SCRIPT_DIR" --target "$HOME"

echo -e "\n\n${GREEN}🧝🏻‍♀️ Setup Configs is complete 🎉${RESET}\n\n"
