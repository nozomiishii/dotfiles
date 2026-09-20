# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# 自前で更新する cask (Chrome 等) を brew upgrade の対象から外す。scripts/homebrew.sh にも同じ設定がある
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

# lang
export LANG="en_US.UTF-8"

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

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

# mise shims - .zshrc を読まない IDE や非対話シェル向け https://mise.jdx.dev/ide-integration.html
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi
