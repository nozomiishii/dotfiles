# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"

OS_NAME="$(uname -s)"

# Homebrew
homebrew() {
  if [[ "$OS_NAME" == "Darwin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if [[ "$OS_NAME" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi  
}
homebrew

# OrbStack
export DOCKER_HOST="unix:///Users/$USER/.orbstack/run/docker.sock"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
# shellcheck disable=SC1090
source ~/.orbstack/shell/init.zsh 2> /dev/null || :

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"
