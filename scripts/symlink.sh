#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo -e "🐂 stow"

echo "Pre-removing known conflicting files..."
rm -f "$HOME/.gitconfig"
rm -f "$HOME/.zprofile"
rm -f "$HOME/.zshrc"
rm -f "$HOME/.bashrc"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"
stow --verbose --restow --target="$HOME" home
