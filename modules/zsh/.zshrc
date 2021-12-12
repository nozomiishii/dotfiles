# unicode of 🧙🏿‍♂️ => \U0001f9d9\U0001F3FF\u200d\U0002642
echo '🧙🏿 ...zshrc loading...'

# Package manager
source "$HOME/zinit.zsh"
# source "$HOME/zplug.zsh"
# source "$HOME/oh-my-zsh.zsh"

# Powerlevel10k
source "$HOME/.p10k.zsh"

# Config
source "$HOME/config.zsh"

# Aliases
source "$HOME/alias.zsh"

# Last working dir
source "$HOME/last-working-dir.zsh"

# Functions
source "$HOME/functions.zsh"


# GCP
GC_SDK="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
if [[ -f "$GC_SDK/path.zsh.inc" ]]; then
  source "$GC_SDK/path.zsh.inc"
fi
if [[ -f "$GC_SDK/completion.zsh.inc" ]]; then
  source "$GC_SDK/completion.zsh.inc"
fi

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# yarn
if type yarn > /dev/null 2>&1; then
  export PATH=$PATH:$(yarn global bin)
fi

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
