#!/bin/bash

# ----------------------------------------------------------------
# Usage
# ----------------------------------------------------------------

#
# zsh -c "$(curl -fsSL https://nozomiishii.dev/dotfiles/install)"
#
# -c: Take the first argument as a command to execute
# -f (--fail): Quit silently when a server error occurs.
# -s (--silent): Silent mode. Don't show progress meter or error messages. Makes Curl mute.
# -S (--show-error): Show error message if it fails.
# -L (--location): Enable redirection.
#
# curl -o - https://raw.githubusercontent.com/nozomiishii/dotfiles/main/install.sh | bash
#

# ----------------------------------------------------------------
# Implementation
# ----------------------------------------------------------------

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

ROOT_PATH="$HOME/dotfiles"
CONFIGS_PATH="$ROOT_PATH/configs"

usage() {
  cat << EOF


NAME
    ./install - Install Nozomi's favourite mac setups.


USAGE:
    ./install [OPTIONS]


OPTIONS:
    -a,    --apps          🧝🏻‍♀️ Apps setup
    -b,    --homebrew      🍺 Homebrew setup
    -bf,   --homebrew-full  🍺 Homebrew setup(full)
    -c,    --code          🦄 Clone repositories
    -d,    --drive         🌎 Sync with google drive
    -e,    --environment   🌝 Environment setup
    -h,    --help          💡 Print this usage
    -k,    --sshkey        🔐 Generate ssh key
    -l,    --symlink       🗂 Symbolic link
    -m,    --macos         💻 MacOS setup
    -r,    --reinstall     ♻️ Reinstall this dotfiles repository
    -ul=*, --unlink=*      👋 Unlinking Symbolic links



EOF
}

pre_sudo() {
  # Ask for the administrator password upfront
  sudo -v
  # Temporarily increasing sudo's timeout until the process has finished
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2> /dev/null &
}

# Sets up the dotfiles repository by cloning the repository,
# initializing and updating Git submodules, and changing the remote URL to SSH.
setup_dotfiles_repository() {
  local repo="nozomiishii/dotfiles"
  local remote_url="https://github.com/${repo}.git"
  local ssh_url="git@github.com:${repo}.git"
  local dotfiles_dir="${HOME}/dotfiles"

  printf "👨🏻‍🚀 Cloning %s...\n" "${repo}"
  git clone "${remote_url}" "${dotfiles_dir}"

  printf "👨🏻‍🚀 Initializing and updating Git submodules...\n"
  (cd "${dotfiles_dir}" && git submodule update --init --recursive)

  printf "👨🏻‍🚀 Changing remote URL to SSH...\n"
  (cd "${dotfiles_dir}" && git remote set-url origin "${ssh_url}")
}

reinstall() {
  cd "$HOME"
  echo "♻️ Reinstall this dotfiles repository"

  rm -rf "$HOME"/dotfiles
  setup_dotfiles_repository

  exec $SHELL
}

# Homebrew
setup_homebrew() {
  echo "🍺 Homebrew setup"
  pre_sudo
  source "$ROOT_PATH/src/homebrew/homebrew.sh"
}

# MacOS
# Dependencis | Homebrew
setup_macos() {
  echo "💻 MacOS setup"
  pre_sudo
  source "$ROOT_PATH/src/macos.sh"
}

# Link
# Dependencis | Homebrew
link_modules() {
  echo "🗂 Symbolic link"

  # shellcheck disable=SC2046
  stow -vd "$CONFIGS_PATH" -t ~ -R $(ls "$CONFIGS_PATH")
}

# Unlink
# Dependencis | Homebrew
unlink_modules() {
  echo "👋 Unlinking symbolic links"
  stow -vD -d "$CONFIGS_PATH" -t ~ "$MODULES"
  exit
}

# Apps
# Dependencis | Homebrew | Link
setup_apps() {
  echo "🧝🏻‍♀️ Apps setup"
  source "$ROOT_PATH/src/apps.sh"
}

# Environment
# Dependencis | Homebrew | Link | Apps (agree to the Xcode license)
setup_environment() {
  echo "🌝 Environment setup"
  pre_sudo

  # if ! command -v dfx > /dev/null 2>&1; then
  #   echo "🌝 Environment setup(dfx)"
  #   DFX_VERSION=0.9.3 sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
  # fi

  echo "🌝 Environment setup"
  source "$ROOT_PATH/src/env.sh"
}

# Code
# Dependencis | Homebrew
setup_repositoris() {
  echo "🦄 Clone repositories"
  source "$ROOT_PATH/src/code.sh"
}

# SSHkey
# Dependencis | Homebrew
generate_sshkey() {
  echo "🔐 Generate ssh key"
  source "$ROOT_PATH/src/sshkey.sh"
}

# Drive
# Dependencis | Homebrew, Mirror Google Drive files
sync_with_drive() {
  echo "🌎 Sync with google drive"
  source "$ROOT_PATH/src/drive.sh"
}

# This function installs the Xcode Command Line Tools if they are not already installed.
#
# @See
# https://gist.github.com/mokagio/b974620ee8dcf5c0671f
# http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line
install_xcode_cli_tools() {
  # Check if Xcode CLI tools are already installed by trying to print the SDK path.
  if ! xcode-select -p &> /dev/null; then
    echo "👨🏻‍🚀 Xcode CLI tools not found. Installing them..."
    TEMP_FILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    touch "${TEMP_FILE}"

    CLI_TOOLS=$(softwareupdate -l \
      | grep "\*.*Command Line" \
      | tail -n 1 | sed 's/^[^C]* //')

    echo "👨🏻‍🚀 Installing: ${CLI_TOOLS}"
    softwareupdate -i "${CLI_TOOLS}" --verbose

    rm "${TEMP_FILE}"
  else
    echo "👨🏻‍🚀 Xcode CLI tools OK"
  fi
}

if [ ! "$@" ]; then
  printf "\n👨🏻‍🚀 Install the best Mac setup for you!! \n"

  pre_sudo
  cd "$HOME"

  echo "👨🏻‍🚀 Checking Xcode CLI tools"
  install_xcode_cli_tools

  if [ ! -d "$HOME"/dotfiles ]; then
    setup_dotfiles_repository
  fi

  # Turn display off after: Never
  sudo pmset -c displaysleep 0
  # Prevent your mac from sleeping automatically when the display is off
  sudo pmset -c sleep 0

  chmod +x "$HOME"/dotfiles/install.sh
  chmod +x "$HOME"/dotfiles/src/*

  setup_homebrew
  setup_macos
  link_modules
  setup_apps
  setup_environment

  echo "👨🏻‍🚀 Open the apps that needs to be configured"
  open -b com.apple.systempreferences
  open "/Applications/Google Drive.app"
  open "/Applications/Google Chrome.app"
  open "/Applications/Raycast.app"
  open "/Applications/1Password.app"
  open "/Applications/Karabiner-Elements.app"
  open /users
  open https://github.com/nozomiishii/dotfiles

  printf "🎉 The dotfiles installation is complete \n\n"
  # Turn display off after: 15 mins
  sudo pmset -c displaysleep 15

  printf "👨🏻‍🚀 Restart the mac \n"
  printf "run: \n"
  printf "  sudo reboot \n\n\n"
fi

for i in "$@"; do
  case "$i" in
    -a | --apps)
      setup_apps
      shift
      ;;
    -b | --homebrew)
      setup_homebrew
      shift
      ;;
    -bf | --homebrew-full)
      export setup_homebrew_full=true
      setup_homebrew
      shift
      ;;
    -c | --code)
      setup_repositoris
      shift
      ;;
    -d | --drive)
      sync_with_drive
      shift
      ;;
    -e | --environment)
      setup_environment
      shift
      ;;
    -h | --help)
      usage
      shift
      ;;
    -k | --sshkey)
      generate_sshkey
      shift
      ;;
    -l | --symlink)
      link_modules
      shift
      ;;
    -m | --macos)
      setup_macos
      shift
      ;;
    -r | --reinstall)
      reinstall
      shift
      ;;
    -ul=* | --unlink=*)
      MODULES="${i#*=}"
      unlink_modules
      shift
      ;;
    *)
      usage
      shift
      ;;
  esac
done
