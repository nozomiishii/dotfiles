#!/usr/bin/env zsh
echo "\n🦄 Cloning repositoris...\n"

if [ ! $CODE_DIR ]; then
  CODE_DIR="$HOME/Code"
fi

git clone https://github.com/nozomiishii/dev $CODE_DIR/nozomiishii/dev
