#!/bin/bash
# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bash_profile.pre.bash" ]] && . "$HOME/.fig/shell/bash_profile.pre.bash"

# unicode of 🧙🏿‍♂️ => \U0001f9d9\U0001F3FF\u200d\U0002642
echo '🧙🏿 ...bashrc loading...'

# Config
# source "$HOME/.bash/config.sh"

# Aliases
source "$HOME/.bash/alias.sh"

# Last working dir
# source "$HOME/.bash/last-working-dir.sh"

# Functions
# source "$HOME/.bash/functions.sh"

# thefuck
# eval $(thefuck --alias)

# yarn
if type yarn > /dev/null 2>&1; then export PATH="$(yarn global bin):$PATH"; fi

export BASH_SILENCE_DEPRECATION_WARNING=1

# grep setting
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;32'

# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bash_profile.post.bash" ]] && . "$HOME/.fig/shell/bash_profile.post.bash"
