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

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BACKUP_DIR="$(cd "$SCRIPT_DIR/../backup" && pwd)"

# ----------------------------------------------------------------
# Functions
# ----------------------------------------------------------------
print_error() {
  local message=$1
  local red="\033[1;31m"
  local reset='\033[0m'

  echo -e "${red}ERROR: ${message}${reset}"
}

print_success() {
  local message=$1
  local green='\033[0;32m'
  local reset='\033[0m'

  echo -e "${green}\n\n${message}${reset}\n\n"
}

get_oldest_file() {
  local dir_path=$1
  local oldest_file

  # Set Internal Field Separator to newline
  IFS=$'\n'

  # Find all files in the specified directory and print their modification time and file path.
  # Sort the files by modification time (oldest to newest).
  # Get the first file (the oldest) from the sorted list.
  # Use awk to print only the file path, handling file names with spaces.
  oldest_file=$(find "$dir_path" -type f -exec stat -f "%m %N" {} \; | sort -n | head -n 1 | awk -F' ' '{ for(i=2; i<NF; i++) printf $i " "; print $NF }')

  # Reset Internal Field Separator to default (space, tab, newline)
  IFS=$' \t\n'

  echo "$oldest_file"
}

remove_oldest_config() {
  local old_config_file

  old_config_file=$(get_oldest_file "$BACKUP_DIR")

  echo "old_config_file"
  mv "$old_config_file" "$HOME/.Trash"

  echo -e "\nRemove the old config file: $old_config_file\n"
}

update_raycast_config() {
  git add "$BACKUP_DIR"
  git commit --no-verify -m "chore(backup): update Raycast config"

  local current_branch
  current_branch=$(git branch --show-current)

  git pull origin "$current_branch"
  git push origin "$current_branch"
}

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
echo -e "🚁 Update Raycast Config\n\n"

backup_files_length=$(find "$BACKUP_DIR" -type f | wc -l)

if [ "$backup_files_length" -eq 0 ]; then
  print_error "No backup files. Export your Raycast app settings to $BACKUP_DIR"
  exit 1
fi

if [ "$backup_files_length" -eq 1 ]; then
  print_error "No duplicate backup files. Export your Raycast app settings to $BACKUP_DIR"
  exit 1
fi

ls -lt "$BACKUP_DIR"

remove_oldest_config
update_raycast_config

print_success "🚁 Update Raycast Config is Complete 🎉"
