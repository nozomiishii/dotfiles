#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# ----------------------------------------------------------------
# Guard
# ----------------------------------------------------------------
COMMITTED_FILES_DIFF=$(git diff --name-only "HEAD@{1}" HEAD)
if ! echo "$COMMITTED_FILES_DIFF" | grep -q "src/homebrew/"; then
  exit 0
fi
echo "$COMMITTED_FILES_DIFF"

# ----------------------------------------------------------------
# Dependencies
# ----------------------------------------------------------------
maintenance_brewfile_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/remove_temp_files/remove_temp_files.sh
source "$maintenance_brewfile_dir/../../utils/remove_temp_files/remove_temp_files.sh"
# shellcheck source=../../utils/request_admin_privileges/request_admin_privileges.sh
source "$maintenance_brewfile_dir/../../utils/request_admin_privileges/request_admin_privileges.sh"

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
maintenance_brewfile() {
  echo -e "🍺 Starting Brewfile maintenance\n"
  request_admin_privileges

  local brewfile_merged_path='/tmp/Brewfile_merged'
  remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

  echo -e "🍺 Merging temporary Brewfile...\n"
  local brewfiles_path="$HOME/dotfiles/src/homebrew/Brewfiles"
  cat "$brewfiles_path/essential" "$brewfiles_path/optional" "$brewfiles_path/mac/mac_essential" "$brewfiles_path/mac/mac_optional" > $brewfile_merged_path

  # Uninstall packages not listed in the merged Brewfile, with details on what is being removed
  echo -e "🍺 Performing Brewfile cleanup...\n"
  brew bundle cleanup --verbose --file=$brewfile_merged_path --force
  remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

  # Remove outdated versions of installed packages and unnecessary files to free up disk space
  echo -e "🍺 Cleaning up old packages and files...\n"
  brew cleanup --verbose

  # Upgrade all installed packages to their latest versions
  echo -e "🍺 Upgrading installed packages...\n"
  brew upgrade --verbose

  echo -e "\n🍺 Brewfile maintenance is complete🎉\n\n"
}
maintenance_brewfile