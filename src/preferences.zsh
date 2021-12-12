#!/usr/bin/env zsh
echo "🧝🏻‍♀️ Starting Third-Party Software Setup \n"


APP_PREFERENCES="$HOME/dotfiles/apps"


echo "- 🦄 Clone Repos"
CODE_DIR="$HOME/Code"
if [ ! -d $CODE_DIR ]; then
  mkdir -p $CODE_DIR
fi

if [ ! -d $CODE_DIR/nozomiishii/dev ]; then
  git clone https://github.com/nozomiishii/dev $CODE_DIR/nozomiishii/dev
fi


echo '- 👾 NeoVim'
# Turn key repear on
defaults write -g ApplePressAndHoldEnabled -bool false
# Install vim-plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Install plugins
pip3 install --upgrade pynvim
vim +PlugInstall +qall > /dev/null


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


echo "\n🎉 Completed Third-Party Software Setup\n"

echo "- 👼 Killall..."
killall Dock
killall Finder
killall SystemUIServer
sudo killall cfprefsd
sudo killall corebrightnessd
