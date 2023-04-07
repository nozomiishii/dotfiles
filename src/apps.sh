#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

printf "🧝🏻‍♀️ Starting Apps setup... \n"

APPS_PATH="$HOME/dotfiles/apps"

echo "- 🤖 Automator"
if [ ! -f "$HOME/Desktop/OpenWithVisualStudioCode.workflow" ]; then
  cp -r "$HOME/dotfiles/apps/Automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi

echo "- 🐟 VSCode"
VSCODE_PATH="$HOME/Library/Application Support/Code/User"
if [ ! -d "$VSCODE_PATH" ]; then
  mkdir -p "$VSCODE_PATH"
  open "/Applications/Visual Studio Code.app"
fi
stow -vd "$APPS_PATH" -t "$VSCODE_PATH" VSCode

echo "- 🥒 tmux"
"$HOME/dotfiles/submodules/tpm/bin/install_plugins"

if [ ! -e "/Applications/Xcode.app" ]; then
  echo "🥲 Xcode not found"
  echo "Xcode and NeoVim settings were skipped."
  echo "You will need to manually run the following command later"
  printf "\n ~/dotfiles/install -a \n"

else
  echo "- 🍎 Xcode"
  XCODE_PATH="$HOME/Library/Developer/Xcode/UserData"
  if [ ! -d "$XCODE_PATH" ]; then
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
    mkdir -p "$XCODE_PATH"
    open "/Applications/XCode.app"
  fi
  if [ -d "$HOME"/Library/Developer/Xcode/UserData/KeyBindings ]; then
    rm -r "$HOME"/Library/Developer/Xcode/UserData/KeyBindings
  fi
  stow -vd "$APPS_PATH" -t "$XCODE_PATH" Xcode

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
# https://github.com/moretension/duti/
duti -s com.microsoft.VSCode yaml all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.VSCode css all
duti -s com.microsoft.VSCode markdown all
duti -s com.microsoft.VSCode sh all

printf "🎉 The App setup is complete \n\n"
