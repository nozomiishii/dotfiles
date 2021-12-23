#!/usr/bin/env zsh
echo "🧝🏻‍♀️ Starting Apps setup... \n"
set -e


APPS_PATH="$HOME/dotfiles/apps"


echo "- 🎮 iTerm2"
# General > Preferences > check "Load preferences from a custom folder or URL"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Restore from the backup
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$APPS_PATH/iTerm2"
# General > Preferences > Save changes: when quits 
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


echo "- 🤖 Automator"
if [ ! -f "$HOME/Desktop" ]; then
  cp -r "$HOME/dotfiles/apps/Automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi


echo "- 🐟 VSCode"
VSCODE_PATH="$HOME/Library/Application Support/Code/User"
if [ ! -d $VSCODE_PATH ]; then
  open "/Applications/Visual Studio Code.app"
fi
stow -vd "$APPS_PATH" -t $VSCODE_PATH VSCode


echo "- 🍎 Xcode"
XCODE_PATH="$HOME/Library/Developer/Xcode/UserData"
if [ ! -d $XCODE_PATH ]; then
  sudo xcodebuild -runFirstLaunch
  open "/Applications/XCode.app"
fi
if [ -d $HOME/Library/Developer/Xcode/UserData/KeyBindings ]; then
  rm -r $HOME/Library/Developer/Xcode/UserData/KeyBindings
fi
stow -vd "$APPS_PATH" -t $XCODE_PATH Xcode


# XCode required to install vim plug
echo '- 👾 NeoVim'
# Turn key repear on
defaults write -g ApplePressAndHoldEnabled -bool false

# Plug Install
PLUG_PATH=~/.local/share/nvim/site/autoload/plug.vim
if [ ! -f "$PLUG_PATH" ]; then
  echo '👾: Setup vim-plug'
  sh -c "curl -fLo $PLUG_PATH --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  echo 'Install Neovim Plugins'
  pip3 install -U neovim
  nvim +PlugInstall +qall
fi


# You will get a Bootstrap failed error, so run it last.
echo "- 🤡 yabai"
brew services start skhd
brew services start yabai



echo "🎉 The App setup is complete \n\n"
