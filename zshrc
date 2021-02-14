echo '🧙🏿‍♂️.zshrc loading...'
# Path to your oh-my-zsh installation.
export ZSH="/Users/nozomi/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Syntax highlighting for man pages using
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Extensions
# Oh my zsh with autosuggestions & syntax-highlighting 
# https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95
if [ ! -d "$ZSH_CUSTOM"/plugins/zsh-autosuggestions ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi
if [ ! -d "$ZSH_CUSTOM"/plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

source $ZSH/oh-my-zsh.sh
plugins=(git last-working-dir zsh-autosuggestions zsh-syntax-highlighting)

# Aliases   
alias dot='cd ~/Google\ Drive/dotfiles'
alias dotst='cd ~/Google\ Drive/dotfiles && code .'
alias noz='cd ~/code/non-b3/nozomiishii/c2021'
alias nost='cd ~/code/non-b3/nozomiishii/c2021 && code . && yarn dev'
alias work='cd ~/code/non-b3/workbench'
alias job='cd ~/code/non-b3/job/homehub'
alias quit='exec $SHELL -l'
alias zz='source ~/.zshrc'
alias ll='exa -laFh --git'
alias ls='exa'

# functions
mkcd(){
  mkdir -p "$@" && cd "$_"
}

# ruby env
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# node env
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#Homebrew
export HOMEBREW_CASK_OPTS="--no-quarantine"
