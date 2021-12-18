#!/usr/bin/env zsh
echo "🌎 Starting syncing with google drive... \n"
set -e


GDRIVE_PATH="$HOME/My Drive"
if [ ! -d "$GDRIVE_PATH" ]; then
  echo "🥲 $GDRIVE_PATH not found"
  echo "💡 Sign in to Google Drive"
  exit
fi


echo "- 🐵 Blender"
ln -nfs "$GDRIVE_PATH/Blender" "$HOME/Library/Application Support/Blender"
ll "$HOME/Library/Application Support/Blender"


echo "🎉 Syncing with google drive is complete \n\n"
