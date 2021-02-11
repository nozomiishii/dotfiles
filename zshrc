echo '🧙🏿‍♂️.zshrc loading...'
# Path to your oh-my-zsh installation.
export ZSH="/Users/nozomi/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Extensions
plugins=(git last-working-dir)
source $ZSH/oh-my-zsh.sh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliases   
alias dot='cd ~/Google\ Drive/dotfiles'
alias dotst='cd ~/Google\ Drive/dotfiles && code .'
alias noz='cd ~/code/non-b3/nozomiishii/c2021'
alias nost='cd ~/code/non-b3/nozomiishii/c2021 && code . && yarn dev'
alias work='cd ~/code/non-b3/workbench'
alias job='cd ~/code/non-b3/job/homehub'
alias rest='exec $SHELL -l'
alias sz='source ~/.zshrc'

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
