#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Update Raycast config
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🚁
# @raycast.packageName System

# Documentation:
# @raycast.description Update Raycast config
# @raycast.author Nozomi Ishii
# @raycast.authorURL https://github.com/nozomiishii

set -Ceu

TEXT_RED="\033[1;31m"
CONFIG_PATH="$HOME/dotfiles/apps/Raycast"

printf "🚁 Update Raycast Config\n\n"

backup_files_length=$(find "$CONFIG_PATH" -type f | wc -l)

if [ "$backup_files_length" -eq 0 ]; then
  echo -e "${TEXT_RED}ERROR: No backup files. Export your Raycast app settings to $CONFIG_PATH"
  exit 1
fi

if [ "$backup_files_length" -eq 1 ]; then
  echo -e "${TEXT_RED}ERROR: No duplicate backup files. Export your Raycast app settings to $CONFIG_PATH"
  exit 1
fi

ls -lt "$CONFIG_PATH"
# shellcheck disable=SC2012
old_config_file=$(ls -t "$CONFIG_PATH" | tail -n 1)

rm "$CONFIG_PATH/$old_config_file"
echo ""
echo "Remove the old config file: $old_config_file"
echo ""

git add "$CONFIG_PATH"

git commit --no-verify -m "feat: update Raycast config"

current_branch=$(git branch --show-current)
git pull origin "$current_branch"
git push origin "$current_branch"

printf "\n\n🎉 Update Success 🎉\n"
