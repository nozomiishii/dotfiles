# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# Powerlevel10k
powerlevel10k_prefix="$(brew --prefix 2> /dev/null)"
if [ -f "${powerlevel10k_prefix}/opt/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  # shellcheck disable=SC1091
  source "${powerlevel10k_prefix}/opt/powerlevel10k/powerlevel10k.zsh-theme"
fi
if [ -f "$HOME/.zsh/p10k.zsh" ]; then
  # shellcheck disable=SC1094
  source "$HOME/.zsh/p10k.zsh"
fi

# Package managers
source "$HOME/.zsh/antigen.zsh"

# Config
source "$HOME/.zsh/config.zsh"

# Aliases
source "$HOME/.zsh/alias.zsh"

# Last working dir
source "$HOME/.zsh/last-working-dir.zsh"

# Functions
source "$HOME/.zsh/functions.zsh"

# lang
export LANG="en_US.UTF-8"

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Node(Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# direnv
if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Python
if command -v pyenv > /dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv > /dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# Ruby
if command -v rbenv > /dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
