#!/usr/bin/env zsh
echo "🧝🏻‍♀️ Starting App Setup... \n"
set -e


APP_PREFERENCES="$HOME/dotfiles/apps"


echo '- 👾 NeoVim'
# Turn key repear on
defaults write -g ApplePressAndHoldEnabled -bool false

# Plug Install
PLUG_PATH=~/.local/share/nvim/site/autoload/plug.vim
if [ ! -f "$PLUG_PATH" ]; then
  echo '👾: Setup vim-plug'
  sh -c "curl -fLo $plug_path --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  echo 'Install Neovim Plugins'
  pip3 install -U neovim
  nvim +PlugInstall +qall
fi


echo "- 🐟 VSCode"
VSCODE_USERDATA="$HOME/Library/Application Support/Code/User"
CUSTOMIZED_VSCODE_USERDATA="$APP_PREFERENCES/VSCode"

VSCODE_USERDATA_ITEMS=("keybindings.json" "settings.json" "snippets")
for item in ${VSCODE_USERDATA_ITEMS[@]}; do
  rm -rf "$VSCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_VSCODE_USERDATA/$item" "$VSCODE_USERDATA/$item"
  if [ -L "$VSCODE_USERDATA/$item" ]; then
    echo "Created Link: $VSCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$VSCODE_USERDATA"


echo "- 🍎 Xcode"
XCODE_USERDATA="$HOME/Library/Developer/Xcode/UserData"
CUSTOMIZED_XCODE_USERDATA="$APP_PREFERENCES/Xcode/UserData"

XCODE_USERDATA_ITEMS=("CodeSnippets" "FontAndColorThemes" "KeyBindings")
for item in ${XCODE_USERDATA_ITEMS[@]}; do
  # Need rm -rf to symbolic-link KeyBindings folder
  rm -rf "$XCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_XCODE_USERDATA/$item" "$XCODE_USERDATA/$item"
  if [ -L "$XCODE_USERDATA/$item" ]; then
    echo "Created Link: $XCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$XCODE_USERDATA"


PYCHARM_VERSION="CE2021.2"
echo "- 🐍 PyCharm$PYCHARM_VERSION"

PYCHARM_USERDATA="$HOME/Library/Application Support/JetBrains/PyCharm$PYCHARM_VERSION"
CUSTOMIZED_PYCHARM_USERDATA="$APP_PREFERENCES/PyCharm"

rm -rf "$PYCHARM_USERDATA"
ln -nfsv "$CUSTOMIZED_PYCHARM_USERDATA" "$PYCHARM_USERDATA"
ls -l "$PYCHARM_USERDATA"



ANDROID_STUDIO_VERSION="2020.3"
echo "- 🐸 Android Studio $ANDROID_STUDIO_VERSION"

ANDROID_STUDIO_USERDATA="$HOME/Library/Application Support/Google/AndroidStudio$ANDROID_STUDIO_VERSION"
CUSTOMIZED_ANDROID_STUDIO_USERDATA="$APP_PREFERENCES/AndroidStudio"

rm -rf "$ANDROID_STUDIO_USERDATA"
ln -nfsv "$CUSTOMIZED_ANDROID_STUDIO_USERDATA" "$ANDROID_STUDIO_USERDATA"
ls -l "$ANDROID_STUDIO_USERDATA"


echo "- 🎮 iTerm2"
# General > Preferences > check "Load preferences from a custom folder or URL"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Restore from the backup
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$APP_PREFERENCES/iTerm2"
# General > Preferences > Save changes: when quits 
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


echo "- 🤡 yabai"
brew services start skhd
brew services start yabai


echo "- 🐵 Blender"
BLENDER_USERDATA="$HOME/Library/Application Support/Blender"
CUSTOMIZED_BLENDER_USERDATA="$APP_PREFERENCES/Blender"

rm -rf "$BLENDER_USERDATA"
ln -nfsv "$CUSTOMIZED_BLENDER_USERDATA" "$BLENDER_USERDATA"
ls -l "$BLENDER_USERDATA"


echo "Automator 🤖"
if [ ! -f "$HOME/Desktop" ]; then
  cp -r "$HOME/dotfiles/apps/Automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi

echo "\n🎉 Completed App Setup \n"
