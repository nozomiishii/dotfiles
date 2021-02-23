#!/usr/bin/env zsh
echo "\n🍺Starting Homebrew Setup\n"

export HOMEBREW_CASK_OPTS="--no-quarantine"

if [ ! -f /usr/local/bin/brew ]; then
  echo "brew doesn't exist, continuing with install"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew bundle --verbose
