#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

DOTFILES_DIR="$HOME/dotfiles"

if [[ ! -f "$DOTFILES_DIR/Makefile" ]]; then
  echo "dotfiles directory not found at $DOTFILES_DIR" >&2
  exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Running make homebrew..."
if make -C "$DOTFILES_DIR" homebrew 2>&1; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - make homebrew completed."
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - make homebrew failed."
  osascript -e 'display notification "make homebrew failed. Check /tmp/brew-update.log" with title "Homebrew"'
fi
