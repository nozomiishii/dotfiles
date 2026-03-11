#!/bin/bash

# -C          : Prevent overwriting existing files when redirecting output.
#               - Helps to avoid accidentally overwriting files when using
#                 redirection operators like > or >> in the script.
# -e          : Exit the script if any command returns a non-zero status.
#               - Ensures the script stops on the first error encountered.
# -u          : Exit the script if an undefined variable is used.
#               - Prevents running commands with unintended variables.
# -o pipefail : Change pipeline exit status to the last non-zero exit code
#               in the pipeline, or zero if all commands succeed.
#               - Ensures proper error handling in pipelines.
# -x          : (Optional) Enable command tracing for easier debugging.
#               - Uncomment this option to debug the script.
set -Ceuo pipefail

# Ensure UTF-8 encoding for special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

DOTFILES_REPO="https://github.com/nozomiishii/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "👨🏻‍🚀 Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" pull --rebase
  else
    echo "👨🏻‍🚀 Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  SCRIPT_DIR="$DOTFILES_DIR"
fi

OS_NAME="$(uname -s)"

# ----------------------------------------------------------------
# utils
# ----------------------------------------------------------------
yellow='\033[1;33m'
reset='\033[0m'

request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  echo -e "- 👨🏻‍🚀 Please enter your password to grant sudo access for this operation"
  sudo -v

  SUDOERS_FILE="/etc/sudoers.d/temp_dotfiles_installer"
  sudo sh -c "echo 'Defaults timestamp_timeout=120' > ${SUDOERS_FILE}"
  sudo chmod 0440 "${SUDOERS_FILE}"
  trap 'sudo rm -f "${SUDOERS_FILE}"' EXIT

  sudo -v

  (
    while true; do
      sleep 10
      sudo -n true
      kill -0 "$$" || exit
    done
  ) 2>/dev/null &
}

# This function installs the Xcode Command Line Tools if they are not already installed.
#
# @See
# https://gist.github.com/mokagio/b974620ee8dcf5c0671f
# http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line
install_xcode_cli_tools() {
  echo -e "👨🏻‍🚀 Install Xcode CLI tools"
  echo "- 👨🏻‍🚀 Checking Xcode CLI tools..."

  # Check if Xcode CLI tools are already installed by trying to print the SDK path.
  if xcode-select -p &>/dev/null; then
    echo "- 👨🏻‍🚀 Xcode CLI tools are already installed"
  else
    echo "- 👨🏻‍🚀 Xcode CLI tools not found. Installing them..."
    TEMP_FILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    touch "${TEMP_FILE}"

    CLI_TOOLS=$(softwareupdate -l |
      grep "\*.*Command Line" |
      tail -n 1 | sed 's/^[^C]* //')

    echo "- 👨🏻‍🚀 Installing: ${CLI_TOOLS}"
    softwareupdate -i "${CLI_TOOLS}" --verbose

    rm "${TEMP_FILE}"
  fi

  echo -e "👨🏻‍🚀 Xcode CLI tools are ready to go 🎉"
}

open_config_apps() {
  if [ "${CI:-false}" = "true" ]; then
    echo "Running in CI environment - skipping app opening"
    return
  fi

  echo "👨🏻‍🚀 Open the apps that needs to be configured"
  open -b com.apple.systempreferences
  open "/Applications/Google Drive.app"
  open "/Applications/Google Chrome.app"
  open "/Applications/Raycast.app"
  open "/Applications/1Password.app"
  open /users
  open https://github.com/nozomiishii/dotfiles
  echo "👨🏻‍🚀 Please refer to github to set up the launched application"
}

# ----------------------------------------------------------------
# Homebrew (macOS & Linux)
# ----------------------------------------------------------------
install_homebrew() {
  if [[ "$OS_NAME" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo -e "🍺 Installing Homebrew for Apple Silicon"
      sudo softwareupdate --install-rosetta --agree-to-license
      NONINTERACTIVE=1 \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo -e "🍺 Homebrew already installed — updating Homebrew and installed packages"
      brew update --force --quiet
      brew upgrade --quiet
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ "${OS_NAME}" == "Linux" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo -e "🍺 Installing Homebrew for ${OS_NAME}"
      NONINTERACTIVE=1 \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      echo -e "🍺 Homebrew already installed — updating Homebrew and installed packages"
      brew update --force --quiet
      brew upgrade --quiet
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  # Bundle packages from Brewfile with retries to tolerate transient cask download failures
  local max_attempts="${BREW_BUNDLE_MAX_ATTEMPTS:-5}"
  local attempt=1
  local backoff_base="${BREW_BUNDLE_BACKOFF_SEC:-20}"

  while [ "$attempt" -le "$max_attempts" ]; do
    echo "brew bundle attempt ${attempt}/${max_attempts}"
    if HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}" brew bundle \
      --verbose \
      --cleanup \
      --file="$SCRIPT_DIR/Brewfile"; then
      echo "brew bundle succeeded"
      break
    fi
    if [ "$attempt" -eq "$max_attempts" ]; then
      echo "brew bundle failed after ${max_attempts} attempts"
      exit 1
    fi
    sleep "$((backoff_base * attempt))"
    attempt="$((attempt + 1))"
  done

  brew cleanup --verbose
}

# ----------------------------------------------------------------
# zsh
# ----------------------------------------------------------------
install_zsh() {
  echo -e "🐚 Installing zsh"

  sudo apt update && sudo apt install -y zsh
}

# ----------------------------------------------------------------
# Symlink
# ----------------------------------------------------------------
symlink_files() {
  echo -e "🐂 stow"

  echo "Pre-removing known conflicting files..."
  rm -f "$HOME/.gitconfig"
  rm -f "$HOME/.zprofile"
  rm -f "$HOME/.zshrc"
  rm -f "$HOME/.bashrc"

  # Symlink dotfiles using stow with verbose output and restow mode
  # --restow removes existing symlinks and recreates them to ensure clean state
  stow --verbose --restow --target="$HOME" home
}

install_nix() {
  echo "👨🏻‍🚀 Install Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # nixで管理したい
  # devenvの設定うまくいかない
  # echo "👨🏻‍🚀 Install devenv"
  # nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable
}

# ----------------------------------------------------------------
# Install
# ----------------------------------------------------------------
echo -e "${yellow}"
printf '%s\n' \
  "👨🏻‍🚀 Nozomiishii Doting Dotfiles" \
  "   Get ready for your ultimate Mac setup!" \
  "" \
  "██████╗░░█████╗░████████╗███████╗██╗██╗░░░░░███████╗░██████╗" \
  "██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║██║░░░░░██╔════╝██╔════╝" \
  "██║░░██║██║░░██║░░░██║░░░█████╗░░██║██║░░░░░█████╗░░╚█████╗░" \
  "██║░░██║██║░░██║░░░██║░░░██╔══╝░░██║██║░░░░░██╔══╝░░░╚═══██╗" \
  "██████╔╝╚█████╔╝░░░██║░░░██║░░░░░██║███████╗███████╗██████╔╝" \
  "╚═════╝░░╚════╝░░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═════╝░" \
  ""
echo -e "${reset}"

if [[ "$OS_NAME" == "Darwin" ]]; then
  request_admin_privileges
  install_nix
  install_xcode_cli_tools
  install_homebrew
  symlink_files
  bash "$SCRIPT_DIR/scripts/darwin/macos.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
  bash "$SCRIPT_DIR/scripts/automator.sh"
  bash "$SCRIPT_DIR/scripts/nvim.sh"
  bash "$SCRIPT_DIR/scripts/default_apps.sh"
  bash "$SCRIPT_DIR/scripts/clone_github_repos.sh"
  open_config_apps
fi

if [[ "$OS_NAME" == "Linux" ]]; then
  install_nix
  install_zsh
  install_homebrew
  symlink_files
  bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
fi

echo -e "${yellow}"
printf '%s\n' \
  "" \
  "" \
  "" \
  "░█████╗░░█████╗░███╗░░██╗░██████╗░██████╗░░█████╗░████████╗░██████╗██╗" \
  "██╔══██╗██╔══██╗████╗░██║██╔════╝░██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║" \
  "██║░░╚═╝██║░░██║██╔██╗██║██║░░██╗░██████╔╝███████║░░░██║░░░╚█████╗░██║" \
  "██║░░██╗██║░░██║██║╚████║██║░░╚██╗██╔══██╗██╔══██║░░░██║░░░░╚═══██╗╚═╝" \
  "╚█████╔╝╚█████╔╝██║░╚███║╚██████╔╝██║░░██║██║░░██║░░░██║░░░██████╔╝██╗" \
  "░╚════╝░░╚════╝░╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░╚═╝" \
  "" \
  "" \
  "🎉 All dotfiles installation is now complete 🎉" \
  "" \
  "" \
  "👨🏻‍🚀 Restart your mac to reflect the settings. Happy Coding🫰🏻" \
  "" \
  "    run:" \
  "      sudo reboot" \
  "" \
  "" \
  ""
echo -e "${reset}"
