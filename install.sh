#!/bin/bash
set -Ceu
#
# zsh -c "$(curl -fsSL https://nozomiishii.dev/dotfiles/install)"
# -c: Take the first argument as a command to execute
# -f (--fail): Quit silently when a server error occurs.
# -s (--silent): Silent mode. Don't show progress meter or error messages. Makes Curl mute.
# -S (--show-error): Show error message if it fails.
# -L (--location): Enable redirection.
#
# curl -o - https://raw.githubusercontent.com/nozomiishii/dotfiles/main/install.sh | bash

ROOT_PATH="$HOME/dotfiles"
MODULES_PATH="$ROOT_PATH/modules"

usage() {
  cat << EOF


NAME
    ./install - Install Nozomi's favourite mac setups.


USAGE:
    ./install [OPTIONS]


OPTIONS:
    -a,    --apps          🧝🏻‍♀️ Apps setup
    -b,    --homebrew      🍺 Homebrew setup
    -bm,   --homebrew-min  🍺 Homebrew setup(minimum)
    -c,    --code          🦄 Clone repositories
    -d,    --drive         🌎 Sync with google drive
    -e,    --environment   🌝 Environment setup(asdf)
    -h,    --help          💡 Print this usage
    -k,    --sshkey        🔐 Generate ssh key
    -l,    --symlink       🗂 Symbolic link
    -m,    --macos         💻 MacOS setup
    -r,    --reinstall     ♻️ Reinstall this dotfiles repository
    -ul=*, --unlink=*      👋 Unlinking Symbolic links
    -up,   --upgrade       🚀 Upgrading dotfiles



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

upgrade() {
  echo "🚀 Upgrading dotfiles"
  cd "$ROOT_PATH"
  git pull origin main
  printf "\n🚀 Dotfiles upgrade is complete \n\n"
  cd -
}

clone_repo() {
  echo "👨🏻‍🚀 Clone nozomiishii/dotfiles..."
  git clone https://github.com/nozomiishii/dotfiles.git
  cd "$HOME"/dotfiles
  git remote set-url origin git@github.com:nozomiishii/dotfiles.git
  cd "$HOME"
}

reinstall() {
  cd "$HOME"
  echo "♻️ Reinstall this dotfiles repository"

  rm -rf "$HOME"/dotfiles
  clone_repo

  exec $SHELL
}

# Homebrew
setup_homebrew() {
  echo "🍺 Homebrew setup"
  pre_sudo
  source "$ROOT_PATH/src/homebrew.sh"
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
  stow -vd "$MODULES_PATH" -t ~ -R $(ls "$MODULES_PATH")
}

# Unlink
# Dependencis | Homebrew
unlink_modules() {
  echo "👋 Unlinking symbolic links"
  stow -vD -d "$MODULES_PATH" -t ~ "$MODULES"
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
  if ! type dfx > /dev/null 2>&1; then
    echo "🌝 Environment setup(dfx)"
    pre_sudo
    DFX_VERSION=0.9.3 sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
  fi

  echo "🌝 Environment setup(asdf)"
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

if [ ! "$@" ]; then
  printf "\n👨🏻‍🚀 Install the best Mac setup for you!! \n"

  if [[ ! -d /Applications/Xcode.app/Contents/Developer && ! -d /Library/Developer/CommandLineTools ]]; then
    echo "👨🏻‍🚀 Ooops! you need to install xcode-select"
    printf "\n xcode-select --install \n"
    xcode-select --install
    printf "\n👨🏻‍🚀 The installation pop-up will appear\n\n"
    exit
  fi

  pre_sudo
  cd "$HOME"
  if [ -d /Applications/Xcode.app ]; then
    sudo xcodebuild -license accept
  fi
  if [ ! -d "$HOME"/dotfiles ]; then
    clone_repo
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

  echo "👨🏻‍🚀 Open the apps that needs to be configured"
  open -b com.apple.systempreferences
  open "/Applications/Google Drive.app"
  open "/Applications/Google Chrome.app"
  open "/Applications/Alfred 5.app"
  open "/Applications/1Password 7.app"
  open "/Applications/Karabiner-Elements.app"
  open /users
  open https://github.com/nozomiishii/dotfiles

  setup_apps
  setup_environment

  printf "🎉 The dotfiles installation is complete \n\n"
  # Turn display off after: 15 mins
  sudo pmset -c displaysleep 15
  # Bootstrap yabai and skhd
  brew services start --all

  printf "👨🏻‍🚀 Restart the mac \n"
  printf "'sudo reboot' \n\n\n"
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
    -bm | --homebrew-min)
      export setup_homebrew_min=true
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
    -up | --upgrade)
      upgrade
      shift
      ;;
    *)
      usage
      shift
      ;;
  esac
done