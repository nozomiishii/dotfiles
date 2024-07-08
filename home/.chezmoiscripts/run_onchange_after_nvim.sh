#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '- 👾 NeoVim'

if [ "${CI:-false}" = "true" ]; then
  echo "Running in CI environment, exiting script."
  return
fi

if [ ! -e "/Applications/Xcode.app" ]; then
  echo "🧝🏻‍♀️ Xcode not found"
  echo "NeoVim settings were skipped."
  return
fi

# Plug Install
plug_dir="$HOME/.local/share/nvim/site/autoload/plug.vim"

if [ ! -f "$plug_dir" ]; then
  echo '👾: Setup vim-plug'
  sh -c "curl -fLo $plug_dir --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

  echo 'Install Neovim Plugins'
  nvim --headless +PlugInstall +qall
fi
