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
# shellcheck source=../../utils/msg/msg.sh
source "$maintenance_brewfile_dir/../../utils/msg/msg.sh"

# ----------------------------------------------------------------
# Functions
# ----------------------------------------------------------------
# Requests administrator privileges upfront and temporarily increases sudo's timeout
# until the current process has finished.
#
request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  echo -e "- 👨🏻‍🚀 Please enter your password to grant sudo access for this operation"
  sudo -v

  # Temporarily increase sudo's timeout until the process has finished
  (
    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" || exit
    done
  ) 2> /dev/null &
}

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
maintenance_brewfile() {
  msg --title "🍺 Starting Brewfile maintenance"
  request_admin_privileges

  local brewfile_merged_path='/tmp/Brewfile_merged'
  remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

  echo -e "- 🍺 Merging temporary Brewfile..."
  local brewfiles_path="$HOME/dotfiles/src/homebrew/Brewfiles"
  cat "$brewfiles_path/essential" "$brewfiles_path/optional" "$brewfiles_path/mac/mac_essential" "$brewfiles_path/mac/mac_optional" > $brewfile_merged_path

  # Uninstall packages not listed in the merged Brewfile, with details on what is being removed
  echo -e "- 🍺 Performing Brewfile cleanup..."
  brew bundle cleanup --verbose --file=$brewfile_merged_path --force
  remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

  # Remove outdated versions of installed packages and unnecessary files to free up disk space
  echo -e "- 🍺 Cleaning up old packages and files..."
  brew cleanup --verbose

  # Upgrade all installed packages to their latest versions
  echo -e "- 🍺 Upgrading installed packages..."
  brew upgrade --verbose

  msg --success "🍺 Brewfile maintenance is complete🎉"
}
maintenance_brewfile
