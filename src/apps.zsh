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
  mkdir -p $VSCODE_PATH
  open "/Applications/Visual Studio Code.app"
fi
stow -vd "$APPS_PATH" -t $VSCODE_PATH VSCode

if [ ! -e "/Applications/Xcode.app" ]; then
  echo "🥲 Xcode not found"
  echo "Xcode and NeoVim settings were skipped."
  echo "You will need to manually run the following command later"
  echo "\n ~/dotfiles/install -a \n"

else
  echo "- 🍎 Xcode"
  XCODE_PATH="$HOME/Library/Developer/Xcode/UserData"
  if [ ! -d $XCODE_PATH ]; then
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
    mkdir -p $XCODE_PATH
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
    python2 -m pip install --user --upgrade pynvim
    python3 -m pip install --user --upgrade pynvim
    pip3 install -U pip
    pip3 install -U neovim
    nvim --headless +PlugInstall +qall
  fi
fi

echo "- 🗂 Set Default Apps for documents"
duti -s com.microsoft.VSCode yaml all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.VSCode css all

echo "🎉 The App setup is complete \n\n"
