#!/usr/bin/env zsh
echo "\n🍺Starting Homebrew Setup\n"

if [ ! -f /usr/local/bin/brew ]; then
  echo "brew doesn't exist, continuing with install"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew bundle --verbose
