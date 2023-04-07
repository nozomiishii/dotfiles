#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

printf "🍺 Starting Homebrew setup... \n"

arch_name="$(uname -m)"

# For Intel mac
if [ "${arch_name}" = "x86_64" ]; then
  if ! type brew > /dev/null 2>&1; then
    echo "🍺brew doesn't exist, continuing with install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
# For M1 mac
elif [ "${arch_name}" = "arm64" ]; then
  if ! type brew > /dev/null 2>&1; then
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
if [ -f $brewfile_merged_path ]; then
  rm $brewfile_merged_path
fi
if [ -f /tmp/Brewfile_merged.lock.json ]; then
  rm /tmp/Brewfile_merged.lock.json
fi

brewfiles_path="$HOME/dotfiles/src/homebrew/Brewfiles"

if "${setup_homebrew_full:-false}"; then
  printf "🍺 Homebrew setup(MacOS: full)\n"
  cat "$brewfiles_path/essential" "$brewfiles_path/optional" "$brewfiles_path/mac/mac_essential" "$brewfiles_path/mac/mac_optional" > $brewfile_merged_path
else
  printf "🍺 Homebrew setup(MacOS: minimum)\n"
  cat "$brewfiles_path/essential" "$brewfiles_path/mac/mac_essential" > $brewfile_merged_path
fi

brew bundle --verbose --file=$brewfile_merged_path
rm $brewfile_merged_path
rm /tmp/Brewfile_merged.lock.json

printf "🎉 The Homebrew setup is complete \n\n"
