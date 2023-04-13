#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

echo -e "🌎 Starting syncing with google drive... \n"

GDRIVE_PATH="$HOME/My Drive"
if [ ! -d "$GDRIVE_PATH" ]; then
  echo "🥲 $GDRIVE_PATH not found"
  echo "💡 Sign in to Google Drive"
  exit
fi

echo "- ☁️ iCloud"
ln -nfs "$GDRIVE_PATH/License" "$HOME/Library/Mobile Documents/com~apple~CloudDocs/License"
ll "$HOME/Library/Mobile Documents/com~apple~CloudDocs/License"

echo "- 🐵 Blender"
ln -nfs "$GDRIVE_PATH/Blender" "$HOME/Library/Application Support/Blender"
ll "$HOME/Library/Application Support/Blender"

echo -e "🎉 Syncing with google drive is complete \n\n"
