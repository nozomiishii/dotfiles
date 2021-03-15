#!/usr/bin/env zsh
echo "\n🍺Starting Homebrew Setup\n"
sudo -v
# uninstall homebrew
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"

export HOMEBREW_CASK_OPTS="--no-quarantine --appdir=~/Applications"

if ! type brew > /dev/null 2>&1; then
  echo "🍺brew doesn't exist, continuing with install"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew bundle --verbose

# Open applications for Setup
open -a Backup\ and\ Sync
open -a 1Password\ 7
