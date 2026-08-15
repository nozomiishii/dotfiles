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

# lang
export LANG="en_US.UTF-8"

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# pnpm
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# vscode
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# OrbStack
export DOCKER_HOST="unix:///Users/$USER/.orbstack/run/docker.sock"

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
# shellcheck disable=SC1090
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# mise shims - .zshrc を読まない IDE や非対話シェルに mise 管理ツールを見せる。
# 対話シェルでは .zshrc の mise activate が優先され、shims はフォールバックになる。
# ~/.local/bin の PATH 追加は .zshrc なので、ここではフルパスで呼ぶ
# https://mise.jdx.dev/ide-integration.html
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi
