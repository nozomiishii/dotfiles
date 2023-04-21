#!/bin/bash

# ----------------------------------------------------------------
# 🧙🏿‍♂️ Nozomiishii Doting Dotfiles
# ----------------------------------------------------------------

# ----------------------------------------------------------------
# Usage
# ----------------------------------------------------------------
#
# run:
#   curl https://raw.githubusercontent.com/nozomiishii/dotfiles/main/src/install.sh | bash
#
# -L (--location): Enable redirection.
# Alternatively, run:
#   curl -L https://nozomiishii.dev/dotfiles/install | bash
#

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
#
# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

install_dir="$HOME/dotfiles/src"

usage() {
  cat << EOF


NAME
    ./install - Nozomiishii Doting Dotfiles


USAGE:
    ./install [OPTIONS]


OPTIONS:
    -b,    --homebrew      🍺 Homebrew setup
    -bf,   --homebrew-full 🍺 Homebrew setup(full)
    -c,    --configs       🧝🏻‍♀️ Configs setup
    -d,    --drive         🌎 Sync with google drive
    -h,    --help          💡 Print this usage
    -k,    --sshkey        🔐 Generate ssh key
    -l,    --symlink       🗂 Symbolic link
    -m,    --macos         💻 MacOS setup
    -r,    --repo          🦄 Clone repositories
    -t,    --toolchains    🌝 Toolchains setup



EOF
}

msg_error() {
  local message=$1
  local red="\033[1;31m"
  local reset='\033[0m'

  echo -e "${red}ERROR: ${message}${reset}"
}

msg_success() {
  local message=$1
  local green='\033[0;32m'
  local reset='\033[0m'

  echo -e "${green}\n\n${message}${reset}\n\n"
}

msg_title() {
  local message=$1

  echo -e "----------------------------------------------------------------"
  echo -e "${message}"
  echo -e "----------------------------------------------------------------"
  echo -e "\n"
}

# Requests administrator privileges upfront and temporarily increases sudo's timeout
# until the current process has finished.
#
request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  # Ask for the administrator password upfront
  sudo -v

  # Temporarily increase sudo's timeout until the process has finished
  (
    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" || exit
    done
  ) 2> /dev/null &
}

# Sets up the dotfiles repository by cloning the repository,
# initializing and updating Git submodules, and changing the remote URL to SSH.
setup_dotfiles_repository() {
  msg_title "👨🏻‍🚀 Setup Dotfiles Repository"

  local repo="nozomiishii/dotfiles"
  local remote_url="https://github.com/${repo}.git"
  local ssh_url="git@github.com:${repo}.git"
  local dotfiles_dir="${HOME}/dotfiles"

  echo -e "- 👨🏻‍🚀 Cloning ${repo}..."
  git clone "${remote_url}" "${dotfiles_dir}"

  echo -e "- 👨🏻‍🚀 Initializing and updating Git submodules..."
  (cd "${dotfiles_dir}" && git submodule update --init --recursive)

  echo -e "- 👨🏻‍🚀 Changing remote URL to SSH..."
  (cd "${dotfiles_dir}" && git remote set-url origin "${ssh_url}")

  msg_success "👨🏻‍🚀 Setup Dotfiles Repository is complete 🎉"
}

# This function installs the Xcode Command Line Tools if they are not already installed.
#
# @See
# https://gist.github.com/mokagio/b974620ee8dcf5c0671f
# http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line
install_xcode_cli_tools() {
  msg_title "👨🏻‍🚀 Install Xcode CLI tools"
  echo "- 👨🏻‍🚀 Checking Xcode CLI tools..."

  # Check if Xcode CLI tools are already installed by trying to print the SDK path.
  if xcode-select -p &> /dev/null; then
    echo "- 👨🏻‍🚀 Xcode CLI tools are already installed"
  else
    echo "- 👨🏻‍🚀 Xcode CLI tools not found. Installing them..."
    TEMP_FILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    touch "${TEMP_FILE}"

    CLI_TOOLS=$(softwareupdate -l \
      | grep "\*.*Command Line" \
      | tail -n 1 | sed 's/^[^C]* //')

    echo "- 👨🏻‍🚀 Installing: ${CLI_TOOLS}"
    softwareupdate -i "${CLI_TOOLS}" --verbose

    rm "${TEMP_FILE}"
  fi

  msg_success "👨🏻‍🚀 Xcode CLI tools are ready to go 🎉"
}

setup_homebrew() {
  msg_title "🍺 Homebrew setup"

  request_admin_privileges
  source "$install_dir/homebrew/homebrew.sh"
}

# Dependencis | Homebrew
setup_macos() {
  msg_title "💻 MacOS setup"

  request_admin_privileges
  source "$install_dir/macos/macos.sh"
}

# Dependencis
setup_configs() {
  msg_title "🧝🏻‍♀️ Configs setup"

  request_admin_privileges
  source "$install_dir/configs/configs.sh"
}

# Dependencis | Homebrew | Link | Apps (agree to the Xcode license)
setup_toolchains() {
  msg_title "🌝 Toolchains setup"

  # if ! command -v dfx > /dev/null 2>&1; then
  #   echo "🌝 Environment setup(dfx)"
  #   DFX_VERSION=0.9.3 sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
  # fi
  request_admin_privileges
  source "$install_dir/toolchains/toolchains.sh"
}

# Dependencis | Homebrew
setup_repositoris() {
  msg_title "🦄 Clone repositories"
  source "$install_dir/scripts/code.sh"
}

# Dependencis | Homebrew
generate_sshkey() {
  msg_title "🔐 Generate ssh key"
  source "$install_dir/scripts/sshkey.sh"
}

# Dependencis | Homebrew, Mirror Google Drive files
sync_with_drive() {
  msg_title "🌎 Sync with google drive"
  source "$install_dir/scripts/drive.sh"
}

install() {
  cd "$HOME"

  local yellow='\033[1;33m'
  local reset='\033[0m'

  echo -e "${yellow}"
  cat << EOF

👨🏻‍🚀 Nozomiishii Doting Dotfiles
   Get ready for your ultimate Mac setup!

██████╗░░█████╗░████████╗███████╗██╗██╗░░░░░███████╗░██████╗
██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║██║░░░░░██╔════╝██╔════╝
██║░░██║██║░░██║░░░██║░░░█████╗░░██║██║░░░░░█████╗░░╚█████╗░
██║░░██║██║░░██║░░░██║░░░██╔══╝░░██║██║░░░░░██╔══╝░░░╚═══██╗
██████╔╝╚█████╔╝░░░██║░░░██║░░░░░██║███████╗███████╗██████╔╝
╚═════╝░░╚════╝░░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═════╝░



EOF
  echo -e "${reset}"

  request_admin_privileges
  install_xcode_cli_tools

  if [ ! -d "$HOME"/dotfiles ]; then
    setup_dotfiles_repository
  fi

  # Turn display off after: Never
  sudo pmset -c displaysleep 0
  # Prevent your mac from sleeping automatically when the display is off
  sudo pmset -c sleep 0

  chmod +x "$HOME"/dotfiles/src/*

  setup_homebrew
  setup_macos
  setup_configs
  setup_toolchains

  echo "👨🏻‍🚀 Open the apps that needs to be configured"
  open -b com.apple.systempreferences
  open "/Applications/Google Drive.app"
  open "/Applications/Google Chrome.app"
  open "/Applications/Raycast.app"
  open "/Applications/1Password.app"
  open "/Applications/Karabiner-Elements.app"
  open /users
  open https://github.com/nozomiishii/dotfiles
  echo "👨🏻‍🚀 Please refer to github to set up the launched application"

  # Turn display off after: 15 mins
  sudo pmset -c displaysleep 15

  echo -e "${yellow}"
  cat << EOF



░█████╗░░█████╗░███╗░░██╗░██████╗░██████╗░░█████╗░████████╗░██████╗██╗
██╔══██╗██╔══██╗████╗░██║██╔════╝░██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║
██║░░╚═╝██║░░██║██╔██╗██║██║░░██╗░██████╔╝███████║░░░██║░░░╚█████╗░██║
██║░░██╗██║░░██║██║╚████║██║░░╚██╗██╔══██╗██╔══██║░░░██║░░░░╚═══██╗╚═╝
╚█████╔╝╚█████╔╝██║░╚███║╚██████╔╝██║░░██║██║░░██║░░░██║░░░██████╔╝██╗
░╚════╝░░╚════╝░╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░╚═╝


🎉 All dotfiles installation is now complete 🎉


👨🏻‍🚀 Restart your mac to reflect the settings. Happy Coding🫰🏻

    run:
      sudo reboot



EOF
  echo -e "${reset}"
}

main() {
  if [ ! "$@" ]; then
    install
    exit 0
  fi

  for i in "$@"; do
    case "$i" in
      -b | --homebrew)
        setup_homebrew
        shift
        ;;
      -bf | --homebrew-full)
        export setup_homebrew_full=true
        setup_homebrew
        shift
        ;;
      -c | --configs)
        setup_configs
        shift
        ;;
      -d | --drive)
        sync_with_drive
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
      -m | --macos)
        setup_macos
        shift
        ;;
      -r | --repo)
        setup_repositoris
        shift
        ;;
      -t | --toolchains)
        setup_toolchains
        shift
        ;;
      *)
        usage
        shift
        ;;
    esac
  done
}
main "$@"
