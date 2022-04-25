#!/usr/bin/env zsh
echo "🦄 Starting Cloning repositories... \n"
set -e


CODE_DIR="$HOME/Code"
if [ ! -d $CODE_DIR ]; then
  echo "🦄 Creating ./Code ..."
  mkdir -p $CODE_DIR
fi


repos=(
  nozomiishii/.vscode
  nozomiishii/dev
  nozomiishii/cv
  nozomiishii/nozomiishii
  nozomiishii/bots
)

for repo in $repos ; do
  if [ ! -d $CODE_DIR/$repo ]; then
    echo "🦄 $repo"
    git clone git@github.com:$repo.git $CODE_DIR/$repo
  fi
done



echo "🎉 Cloning repositories is complete \n\n"

