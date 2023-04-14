#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Cu
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

cd "$(dirname "$0")" || exit
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# SYMLINKS_DIRS=$(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# brew install stow

# while IFS= read -r SYMLINKS_DIR; do

#   if stow --dir="$SCRIPT_DIR" --target="$HOME" --verbose=2 --restow "$SYMLINKS_DIR"; then
#     echo -e "LINK: $HOME/$SYMLINKS_DIR -> $SCRIPT_DIR/$SYMLINKS_DIR"
#   else
#     mv "$HOME/$SYMLINKS_DIR" "$HOME/.Trash"
#     stow --dir="$SCRIPT_DIR" --target="$HOME" --verbose=2 --restow "$SYMLINKS_DIR"
#   fi

# done <<< "$SYMLINKS_DIRS"

# echo -e "🗂 Symbolic link...\n\n"

# if stow --dir="$SCRIPT_DIR" --target="$HOME" --verbose=2 --restow git; then
#   echo -e "LINK"
# else
#   mv "$HOME/git" "$HOME/.Trash/"
#   stow --dir="$SCRIPT_DIR" --target="$HOME" --verbose=2 --restow git
# fi

# for PACKAGE in shell emacs # ...
# do
#   stow -R -v -d path/to/dotfiles -t ~ $PACKAGE
# done

# if [ -e ~/.gitconfig ] && [ ! -L ~/.gitconfig ]; then
#   echo "Backing up existing .gitconfig file..."
#   mv ~/.gitconfig ~/.gitconfig.backup
# fi

stow_output=$(stow --verbose --target="$HOME" git)
echo "stow_output"
echo "$stow_output"
# file_name=$(echo "$stow_output" | grep -oP '(?<=not owned by stow: )[^ ]+')
file_name=$(echo "$stow_output" | grep -o '(?<=not owned by stow: )[^ ]+')

echo "$file_name"

# stow --target="$HOME" git

echo -e "\n\n${GREEN}🗂 Setup Symbolic link is complete 🎉${NO_COLOR}\n\n"
