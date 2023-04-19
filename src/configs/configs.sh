#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

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
brew install duti
duti -s com.microsoft.VSCode yaml all
duti -s com.microsoft.VSCode json all
duti -s com.microsoft.VSCode css all
duti -s com.microsoft.VSCode markdown all
duti -s com.microsoft.VSCode sh all

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

msg --success "🧝🏻‍♀️ Configs setup is complete 🎉"
