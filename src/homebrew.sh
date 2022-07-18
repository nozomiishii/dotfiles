#!/bin/bash
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
brew bundle --verbose --file "$HOME/dotfiles/Brewfile"

printf "🎉 The Homebrew setup is complete \n\n"
