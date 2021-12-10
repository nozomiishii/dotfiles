#!/usr/bin/env zsh
echo "\n🦖 Starting C# Setup\n"

if [ -d $HOME/.omnisharp ]; then
  ln -fs "$HOME/dotfiles/apps/omnisharp/omnisharp.json" "$HOME/.omnisharp/omnisharp.json"
else
  mkdir "$HOME/.omnisharp"
  touch "$HOME/.omnisharp/omnisharp.json"
fi

# check if it works
ls -l "$HOME/.omnisharp/omnisharp.json"
