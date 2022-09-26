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

config_path="$HOME/dotfiles/apps/Raycast"

printf "🚁 Update Raycast Config\n\n"

backup_files_length=$(find "$config_path" -type f | wc -l)

if [ "$backup_files_length" -ge 2 ]; then
  ls -lt "$config_path"
  # shellcheck disable=SC2012
  old_config_file=$(ls -t "$config_path" | tail -n 1)

  rm "$config_path/$old_config_file"
  echo "Remove file $old_config_file"
fi

git add "$config_path"

git commit --no-verify -m "feat: update raycast config"

printf "🎉 Update Success"
