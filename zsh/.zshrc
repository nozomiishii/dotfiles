echo '🧙🏿‍♂️.zshrc loading...'

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Bundle files
ZSH_SRC_DIR="$HOME/dotfiles/zsh"

# zinit
source "$ZSH_SRC_DIR/zinit.zsh"

# Config
source "$ZSH_SRC_DIR/config.zsh"

# Aliases
source "$ZSH_SRC_DIR/alias.zsh"

# Last working dir
source "$ZSH_SRC_DIR/last-working-dir.zsh"

# Functions
source "$ZSH_SRC_DIR/functions.zsh"

if [[ -f $ZSH_SRC_DIR/tokens.zsh ]]; then
  source "$ZSH_SRC_DIR/tokens.zsh"
fi


# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Ruby env
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Python env
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# n
export N_PREFIX="$HOME/.n"
export PATH="$PATH:$N_PREFIX/bin"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
