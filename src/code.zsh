#!/usr/bin/env zsh
echo "🦄 Starting Cloning repositoris... \n"
set -e


CODE_DIR="$HOME/Code"
if [ ! -d $CODE_DIR ]; then
  echo "🦄 Creating ./Code ..."
  mkdir -p $CODE_DIR
fi


repos=(
  nozomiishii/dev
  nozomiishii/cv
)

for repo in $repos ; do
  if [ ! -d $CODE_DIR/$repo ]; then
    echo "🦄 $repo"
    git clone https://github.com/$repo $CODE_DIR/$repo
  fi
done



echo "\n🎉 Completed Cloning repositoris \n"

