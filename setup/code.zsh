#!/usr/bin/env zsh
echo "\n🦄 Cloning repositoris...\n"

CODE_DIR="$HOME/Code"
if [ ! -d $CODE_DIR ]; then
  mkdir -p $CODE_DIR
fi

if [ ! -d $CODE_DIR/nozomiishii/dev ]; then
  git clone https://github.com/nozomiishii/dev $CODE_DIR/nozomiishii/dev
fi

