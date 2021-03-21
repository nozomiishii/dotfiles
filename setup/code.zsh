#!/usr/bin/env zsh
echo "\n🦄 Cloning repositoris...\n"

if [ ! $CODE_DIR ]; then
  CODE_DIR="$HOME/Code"
fi

git clone https://github.com/nozomiishii/c2021 $CODE_DIR/nozomiishii/c2021

git clone git@github.com:nozomiishii/workbench.git $CODE_DIR/workbench
