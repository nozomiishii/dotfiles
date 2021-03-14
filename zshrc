echo "🧙🏿‍♂️.zshrc loading..."

# Oh my zsh with syntax-highlighting 
# https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
  # zsh compinit: insecure directories
  chmod 755 /usr/local/share/zsh/site-functions
  chmod 755 /usr/local/share/zsh
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 
fi

if [ -d $HOME/.oh-my-zsh ]; then
  # Path to your oh-my-zsh installation.
  export ZSH="$HOME/.oh-my-zsh"
  # Theme
  ZSH_THEME="robbyrussell"

  plugins=(git last-working-dir zsh-syntax-highlighting)
  source $ZSH/oh-my-zsh.sh
fi


# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"


# Aliases 
CODE_DIR="$HOME/Code"

alias dot="cd ~/Google\ Drive/Settings/dotfiles"
alias desk="cd ~/Desktop"
alias plist="cd ~/Library/Preferences"
alias noz="cd $CODE_DIR/nozomiishii/c2021"
alias work="cd $CODE_DIR/workbench"
alias job="cd $CODE_DIR/job/homehub"
alias quit="exec $SHELL -l"
alias zz="source ~/.zshrc"
alias ll="exa -laFh --git"
alias ls="exa"
alias wifi="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"
alias play="chmod +x ./playground.sh && ./playground.sh"


# Functions
mkcd(){
  mkdir -p "$@" && cd "$_"
}


# Ruby env
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"


# Node env
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
