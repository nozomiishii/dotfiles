# unicode of 🧙🏿‍♂️ => \U0001f9d9\U0001F3FF\u200d\U0002642
echo '🧙🏿 ...zshrc loading...'

# Powerlevel10k
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme
source "$HOME/.zsh/p10k.zsh"

# Package managers
source "$HOME/.zsh/antigen.zsh"
# source "$HOME/.zsh/zinit.zsh"
# source "$HOME/.zsh/zplug.zsh"

# Config
source "$HOME/.zsh/config.zsh"

# Aliases
source "$HOME/.zsh/alias.zsh"

# Last working dir
source "$HOME/.zsh/last-working-dir.zsh"

# Functions
source "$HOME/.zsh/functions.zsh"


# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# yarn
if type yarn > /dev/null 2>&1; then export PATH="$(yarn global bin):$PATH"; fi

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
