
echo "🌎 Starting syncing with google drive... \n"
set -e


GDRIVE_PATH="$HOME/My Drive/Blender"


echo "- 🐵 Blender"
ln -nfs "$GDRIVE_PATH/Blender" "$HOME/Library/Application Support/Blender"
ll "$HOME/Library/Application Support/Blender"
