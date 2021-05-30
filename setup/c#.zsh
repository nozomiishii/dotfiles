#!/usr/bin/env zsh
echo "\n🦖 Starting C# Setup\n"

ln -fs "$HOME/Google Drive/Settings/dotfiles/preferences/omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"
# check if it works
ls -l "$HOME/.omnisharp/omnisharp.json"
