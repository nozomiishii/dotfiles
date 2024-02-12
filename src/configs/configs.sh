#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

configs_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/create_symlinks/create_symlinks.sh
source "$configs_dir/../../utils/create_symlinks/create_symlinks.sh"
# shellcheck source=../../utils/msg/msg.sh
source "$configs_dir/../../utils/msg/msg.sh"

# ----------------------------------------------------------------
# main
# ----------------------------------------------------------------
msg --title "🧝🏻‍♀️ Initializing configs setup..."

# ----------------------------------------------------------------
# Symlinks
# ----------------------------------------------------------------
echo "- 🔗 Creating symlinks"
create_symlinks --source "$configs_dir" --target "$HOME"

# ----------------------------------------------------------------
# duti
# ----------------------------------------------------------------
echo "- 🗂 Setting default applications for various document"
if [ ! -e "/Applications/Visual Studio Code.app" ]; then
  msg --warning "- 🧝🏻‍♀️ VSCode not found. installing..."
  brew install visual-studio-code
fi

# Example of how to retrieve the bundle identifier
# osascript -e 'id of app "VLC"'
brew install duti
duti -s com.microsoft.VSCode yaml all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.VSCode css all
duti -s com.microsoft.VSCode markdown all
duti -s com.microsoft.VSCode sh all
duti -s com.microsoft.VSCode js all
duti -s com.microsoft.VSCode ts all
duti -s org.videolan.vlc mp4 all

# ----------------------------------------------------------------
# Automator
# ----------------------------------------------------------------
echo "- 🤖 Automator"
if [ ! -f "$HOME/Desktop/OpenWithVisualStudioCode.workflow" ]; then
  cp -r "$configs_dir/_automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi

# ----------------------------------------------------------------
# tmux
# ----------------------------------------------------------------
echo "- 🥒 tmux"
setup_tmux() {
  "$configs_dir/../../submodules/tpm/bin/install_plugins" || true
}
setup_tmux

# ----------------------------------------------------------------
# Xcode
# ----------------------------------------------------------------
setup_xcode() {
  if [ ! -e "/Applications/Xcode.app" ] || [ "${CI:-false}" = "true" ]; then
    echo "🧝🏻‍♀️ Xcode not found"
    echo "Xcode and NeoVim settings were skipped."

  else
    echo "- 🍎 Xcode"
    local xcode_dir="$HOME/Library/Developer/Xcode/UserData"
    if [ ! -d "$xcode_dir" ]; then
      sudo xcodebuild -license accept
      sudo xcodebuild -runFirstLaunch
      mkdir -p "$xcode_dir"
      open "/Applications/XCode.app"
    fi

    mkdir_handling_broken_symlinks "$HOME"/Library/Developer/Xcode/UserData/KeyBindings
    create_symlinks --source "$configs_dir/_xcode" --target "$xcode_dir"

    # XCode required to install vim plug
    echo '- 👾 NeoVim'
    brew install neovim
    # Turn key repear on
    defaults write -g ApplePressAndHoldEnabled -bool false

    # Plug Install
    local plug_dir="$HOME/.local/share/nvim/site/autoload/plug.vim"
    if [ ! -f "$plug_dir" ]; then
      echo '👾: Setup vim-plug'
      sh -c "curl -fLo $plug_dir --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
      echo 'Install Neovim Plugins'
      python3 -m pip install --user --upgrade pynvim
      pip3 install -U pip
      pip3 install -U neovim
      nvim --headless +PlugInstall +qall
    fi
  fi
}
setup_xcode

msg --success "🧝🏻‍♀️ Configs setup is complete 🎉"
