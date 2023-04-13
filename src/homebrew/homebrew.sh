#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
brewfiles_path="$SCRIPT_DIR/Brewfiles"
# shellcheck source=../../utils/remove_temp_files/remove_temp_files.sh
source "$SCRIPT_DIR/../../utils/remove_temp_files/remove_temp_files.sh"

echo -e "🍺 Starting Homebrew setup...\n\n"

# ----------------------------------------------------------------
# Homebrew
# ----------------------------------------------------------------
arch_name="$(uname -m)"

# For Intel mac
if [ "${arch_name}" = "x86_64" ]; then
  if ! command -v brew > /dev/null 2>&1; then
    echo "🍺brew doesn't exist, continuing with install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
# For M1 mac
elif [ "${arch_name}" = "arm64" ]; then
  if ! command -v brew > /dev/null 2>&1; then
    echo '🍺Install Rosetta 2'
    sudo softwareupdate --install-rosetta --agree-to-license

    echo "🍺brew doesn't exist, continuing with install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

export HOMEBREW_CASK_OPTS="--no-quarantine --appdir=~/Applications"

# ----------------------------------------------------------------
# Brewfile
# ----------------------------------------------------------------

brewfile_merged_path='/tmp/Brewfile_merged'
remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

if "${setup_homebrew_full:-false}"; then
  echo -e "🍺 Homebrew setup(MacOS: full)\n"
  cat "$brewfiles_path/essential" "$brewfiles_path/optional" "$brewfiles_path/mac/mac_essential" "$brewfiles_path/mac/mac_optional" > $brewfile_merged_path
else
  echo -e "🍺 Homebrew setup(MacOS: minimum)\n"
  cat "$brewfiles_path/essential" "$brewfiles_path/mac/mac_essential" > $brewfile_merged_path
fi

brew bundle --verbose --file=$brewfile_merged_path
remove_temp_files $brewfile_merged_path '/tmp/Brewfile_merged.lock.json'

# ----------------------------------------------------------------
# Result
# ----------------------------------------------------------------
echo -e "\n\n${GREEN}🎉 The Homebrew setup is complete 🎉${NO_COLOR}\n\n"
