#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# shellcheck source=../../utils/remove_temp_files.sh
source "$SCRIPT_DIR/../../utils/remove_temp_files.sh"
# shellcheck source=../../utils/request_admin_privileges.sh
source "$SCRIPT_DIR/../../utils/request_admin_privileges.sh"

COMMITTED_FILES_DIFF=$(git diff --name-only "HEAD@{1}" HEAD)
if ! echo "$COMMITTED_FILES_DIFF" | grep -q "src/homebrew/"; then
  exit 0
fi

echo "$COMMITTED_FILES_DIFF"

printf "🍺 Starting Brewfile maintenance\n"
request_admin_privileges

brewfile_merged_path='/tmp/Brewfile_merged'
remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

printf "🍺 Merging temporary Brewfile...\n"
brewfiles_path="$HOME/dotfiles/src/homebrew/Brewfiles"

cat "$brewfiles_path/essential" "$brewfiles_path/optional" "$brewfiles_path/mac/mac_essential" "$brewfiles_path/mac/mac_optional" > $brewfile_merged_path

# Uninstall packages not listed in the merged Brewfile, with details on what is being removed
printf "🍺 Performing Brewfile cleanup...\n"
brew bundle cleanup --verbose --file=$brewfile_merged_path --force
remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

# Remove outdated versions of installed packages and unnecessary files to free up disk space
printf "🍺 Cleaning up old packages and files...\n"
brew cleanup --verbose

# Upgrade all installed packages to their latest versions
printf "🍺 Upgrading installed packages...\n"
brew upgrade --verbose

printf "\n🍺 Brewfile maintenance is complete🎉\n\n"
