echo "🧙🏿‍♂️.zshrc loading..."

# syntax-highlighting 
# https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
  # zsh compinit: insecure directories
  chmod 755 /usr/local/share/zsh/site-functions
  chmod 755 /usr/local/share/zsh
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 
fi

# zsh-completions
# https://github.com/zsh-users/zsh-completions
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-completions ]; then
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
fi


if [ -d $HOME/.oh-my-zsh ]; then
  # Path to your oh-my-zsh installation.
  export ZSH="$HOME/.oh-my-zsh"
  # Theme
  ZSH_THEME="robbyrussell"

  plugins=(git last-working-dir zsh-syntax-highlighting zsh-completions)
  autoload -U compinit && compinit
  source $ZSH/oh-my-zsh.sh
fi


# Syntax highlighting for man command
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Aliases 
CODE_DIR="$HOME/Code"
GOOGLE_DRIVE_DIR="$HOME/Google\ Drive"

alias cddrive="cd $GOOGLE_DRIVE_DIR"
alias dot="cd $GOOGLE_DRIVE_DIR/Settings/dotfiles"
alias alfred="cd $GOOGLE_DRIVE_DIR/Settings/Alfred"
alias desk="cd ~/Desktop"
alias plist="cd ~/Library/Preferences"
alias cdcode="cd $CODE_DIR"
alias noz="cd $CODE_DIR/nozomiishii/c2021"
alias wrk="cd $CODE_DIR/Work/voice-utopia"
alias hbb="hub browse"
alias quit="exec $SHELL -l"
alias zz="source ~/.zshrc"
alias ll="exa -laFh --git"
alias ls="exa"
alias wifi="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"
alias play="chmod +x ./playground.sh && ./playground.sh"
alias yul="yarn upgrade --latest"

# Functions
# Create a directory and move it there
mkcd(){
  mkdir -p "$@" && cd "$_"
}

# Check the connected localhost
lh(){
  echo `ipconfig getifaddr en0`":${1:-3000}" | pbcopy
  echo "\nYour connected IP address is"
  echo `ipconfig getifaddr en0`":${1:-3000}" 
  echo "Copied to clipboard🧙🏿‍♂️\n"
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
