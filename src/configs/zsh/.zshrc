# starship
eval "$(starship init zsh)"

# Initialize zsh's auto-completion system
autoload -Uz compinit
zmodload -i zsh/complist
compinit

# Syntax Highlighting
if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
  # shellcheck disable=SC1091
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# chezmoi
export PATH="$HOME/.local/bin:$PATH"
if command -v chezmoi > /dev/null; then
  eval "$(chezmoi completion zsh)"
fi

# Config
source "$HOME/.zsh/config.zsh"

# Aliases
source "$HOME/.zsh/alias/index.zsh"

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
export VOLTA_FEATURE_PNPM=1
export PATH="$VOLTA_HOME/bin:$PATH"

# direnv
if command -v direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi

# Python
if command -v pyenv > /dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  command -v pyenv > /dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# Ruby
if command -v rbenv > /dev/null; then
  eval "$(rbenv init -)"
fi

# Warp
# Automatically "Warpify" subshells
# shellcheck disable=SC2016
printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh" }}\x9c'
