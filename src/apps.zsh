#!/usr/bin/env zsh
echo "🧝🏻‍♀️ Starting Apps Setup... \n"
set -e


APPS_PATH="$HOME/dotfiles/apps"


echo "- 🎮 iTerm2"
# General > Preferences > check "Load preferences from a custom folder or URL"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Restore from the backup
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$APPS_PATH/iTerm2"
# General > Preferences > Save changes: when quits 
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


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


echo "- 🐟 VSCode"
stow -vd "$APPS_PATH" -t "$HOME/Library/Application Support/Code/User" VSCode


echo "- 🍎 Xcode"
stow -vd "$APPS_PATH" -t "$HOME/Library/Developer/Xcode/UserData" Xcode


# echo "- 🐵 Blender"
# stow -vd "$APPS_PATH" -t "$HOME/Library/Application Support/Blender" Blender


echo "- 🤖 Automator"
if [ ! -f "$HOME/Desktop" ]; then
  cp -r "$HOME/dotfiles/apps/Automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi


echo "- 🤡 yabai"
brew services start skhd
brew services start yabai


echo "\n🎉 Completed App Setup \n"
