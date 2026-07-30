#!/usr/bin/env bash

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
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Code/nozomiishii/dotfiles}"
OS_NAME="$(uname -s)"

# ----------------------------------------------------------------
# utils
# ----------------------------------------------------------------
yellow='\033[1;33m'
reset='\033[0m'

# request_admin_privileges is kept in this file (not extracted to a script)
# because it manages main-process state: it sets an EXIT trap and starts a
# background sudo keepalive. Running it in a subshell would not affect the
# current process, so it must remain here.
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

clone_dotfiles_repo() {
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    return
  fi

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "👨🏻‍🚀 Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" pull --rebase
  else
    echo "👨🏻‍🚀 Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  SCRIPT_DIR="$DOTFILES_DIR"
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
  clone_dotfiles_repo
  bash "$SCRIPT_DIR/scripts/nix.sh"
  bash "$SCRIPT_DIR/scripts/darwin/xcode.sh"
  bash "$SCRIPT_DIR/scripts/homebrew.sh"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  bash "$SCRIPT_DIR/scripts/symlink.sh"
  bash "$SCRIPT_DIR/scripts/darwin/macos.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/claude-code.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/pm.sh"
  bash "$SCRIPT_DIR/scripts/nvim.sh"
  bash "$SCRIPT_DIR/scripts/default_apps.sh"
  bash "$SCRIPT_DIR/scripts/darwin/open_config_apps.sh"
fi

if [[ "$OS_NAME" == "Linux" ]]; then
  clone_dotfiles_repo
  bash "$SCRIPT_DIR/scripts/nix.sh"
  bash "$SCRIPT_DIR/scripts/zsh.sh"
  bash "$SCRIPT_DIR/scripts/homebrew.sh"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  bash "$SCRIPT_DIR/scripts/symlink.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/claude-code.sh"
  bash "$SCRIPT_DIR/scripts/toolchains/pm.sh"
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
  "📦 If Homebrew was interrupted:" \
  "" \
  "    run:" \
  "      make homebrew" \
  "" \
  "" \
  "📦 After restarting, clone your private repositories:" \
  "" \
  "    1. gh auth login" \
  "    2. make repo" \
  "" \
  ""
echo -e "${reset}"
