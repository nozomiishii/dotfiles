echo '🧙🏿‍♂️.zshrc loading...'

# Oh my zsh with syntax-highlighting 
# https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95
if [ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
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
alias dot='cd ~/Google\ Drive/settings/dotfiles'
alias noz='cd ~/code/nozomiishii/c2021'
alias work='cd ~/code/workbench'
alias job='cd ~/code/job/homehub'
alias desk='cd ~/Desktop'
alias quit='exec $SHELL -l'
alias zz='source ~/.zshrc'
alias ll='exa -laFh --git'
alias ls='exa'
alias wifi='networksetup -setairportpower en0 off && networksetup -setairportpower en0 on'
alias cdpl='cd ~/Library/Preferences'

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
