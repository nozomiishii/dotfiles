#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Cu
GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# ----------------------------------------------------------------
# How to unlink:
#   stow -vD -d "$HOME/dotfiles/src/symlinks" -t="$HOME" <Target_dir>
# ----------------------------------------------------------------
echo -e "🗂 Symbolic link...\n\n"
brew install stow

function handle_stow_error() {
  while read -r line; do
    if [[ $line =~ .*existing\ target\ is\ not\ owned\ by\ stow:\ (.*) ]]; then
      target_file="${BASH_REMATCH[1]}"
      echo "Removing existing target file: $target_file"
      rm -f "$HOME/$target_file"
      retry=1
    fi
  done <<< "$1"
}

function stow_target_with_retry() {
  local target="$1"
  local retry=1
  local error_output

  while [ $retry -eq 1 ]; do
    retry=0
    error_output=$(stow --verbose --dir="$SCRIPT_DIR" --target="$HOME" -R "$target" 2>&1)
    handle_stow_error "$error_output"

    if [ $retry -eq 1 ]; then
      echo "Retrying Stow command"
    fi
  done
}

TARGETS=$(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
while IFS= read -r TARGET; do
  stow_target_with_retry "$TARGET"
  echo -e "${GREEN}✓${RESET} LINK: $TARGET"
done <<< "$TARGETS"

echo -e "\n\n${GREEN}🗂 Setup Symbolic link is complete 🎉${RESET}\n\n"
