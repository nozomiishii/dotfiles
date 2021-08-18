# Aliases

# Variables
CODE_DIR="$HOME/Code"
GOOGLE_DRIVE_DIR="$HOME/Google\ Drive"


# Maintenance
alias brewi="./setup/homebrew.zsh"
alias brewclean="brew bundle cleanup --force && brew cleanup && brew upgrade"
alias zclean="zinit self-update && zinit update && zinit delete --clean"
alias dotclean="brewclean && zclean"
alias play="chmod +x ./playground.sh && ./playground.sh"


# Change Directory
alias drive="cd $GOOGLE_DRIVE_DIR"
alias dot="cd $HOME/dotfiles"
alias vimtut="cd $HOME/Tutorials/vimclass && open ."
alias dsk="cd ~/Desktop"
alias plist="cd ~/Library/Preferences"
alias jj="cd $CODE_DIR"
alias noz="cd $CODE_DIR/nozomiishii/c2021"
alias wrk="cd $CODE_DIR/Work"
alias vu="cd $CODE_DIR/Work/voice-utopia"
alias vuapi="cd $CODE_DIR/Work/voice-utopia-api"
alias vuo="cd $CODE_DIR/Work/voice-utopia-office"


# shell
alias quit="exec $SHELL -l"
alias zz="source ~/.zshrc"
alias ll="exa -laFh --git"
alias ls="exa"


# git
alias grmb="git branch --merged|egrep -v '\*|main|dev|stag|prod'|xargs git branch -d && git fetch --prune"
alias deploy="git push origin prod && git checkout main"
alias hbb="hub browse"


# npm
alias prisma="npx prisma"
alias yul="yarn upgrade --latest"


# network
alias wifi="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"
