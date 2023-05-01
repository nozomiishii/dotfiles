# Aliases

# ----------------------------------------------------------------
# Variables
# ----------------------------------------------------------------
CODE_DIR="$HOME/Code"
GOOGLE_DRIVE_DIR="$HOME/Google\ Drive"

# ----------------------------------------------------------------
# NeoVim
# ----------------------------------------------------------------
if command -v nvim > /dev/null 2>&1; then
  alias vi="nvim"
  alias vim="nvim"
  alias view="nvim -R"
  alias vimconfig="vim $HOME/dotfiles/nvim/init.vim"
fi

# ----------------------------------------------------------------
# Maintenance
# ----------------------------------------------------------------
alias brewi="./setup/homebrew.zsh"
alias brewclean="brew bundle cleanup --verbose --file "$HOME/dotfiles/Brewfiles/macos/Brewfile" --force && brew cleanup && brew upgrade"
alias zclean="zinit self-update && zinit update && zinit delete --clean"
alias dotclean="brewclean && zclean"
alias play="chmod +x ./playground.sh && ./playground.sh"

# ----------------------------------------------------------------
# Open VScode
# ----------------------------------------------------------------
alias fj="code ."

# ----------------------------------------------------------------
# Change Directory
# ----------------------------------------------------------------
alias drive="cd $GOOGLE_DRIVE_DIR"
alias dsk="cd ~/Desktop"
alias plist="cd ~/Library/Preferences"
alias wrk="cd $CODE_DIR/Work"

alias dot="cd $HOME/dotfiles"
alias noz="cd $CODE_DIR/nozomiishii"
alias dev="cd $CODE_DIR/nozomiishii/dev"
alias docs="cd $CODE_DIR/nozomiishii/dev/docs"
alias arc="cd $CODE_DIR/nozomiishii/archives"
alias repo="cd $CODE_DIR"

# ----------------------------------------------------------------
# shell
# ----------------------------------------------------------------
alias quit="exec $SHELL -l"
alias zz="exec $SHELL"

if command -v exa > /dev/null 2>&1; then
  alias ls="exa"
  alias ll="exa -laFh --git"
fi

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------
alias grmb="git branch --merged|egrep -v '\*|master|main|dev|develop|development|stag|staging|prod|production'|xargs git branch -d && git fetch --prune"
alias deploy="git push origin prod && git checkout main"
alias ghb="gh browse"
alias devprod="git checkout stag && git pull origin main && git push --force-with-lease origin stag && git checkout prod && git pull origin stag && git push --force-with-lease origin prod && git checkout main"
alias devstag="git checkout stag && git pull origin main && git push --force-with-lease origin stag"
alias stagprod="git checkout prod && git pull origin stag && git push --force-with-lease origin prod && git checkout main"
alias gsmp="git submodule foreach git pull"
alias gil="gh issue list -a nozomiishii"
alias gilw="gh issue list -a nozomiishii -w"

# ----------------------------------------------------------------
# npm
# ----------------------------------------------------------------
alias prisma="npx prisma"
alias yul="yarn upgrade --latest"

# ----------------------------------------------------------------
# network
# ----------------------------------------------------------------
alias wifi="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"

# ----------------------------------------------------------------
# Docker
# ----------------------------------------------------------------
alias dcls="docker container ls"
alias dcr="docker container run"
alias dcs="docker container start -a"
alias dcex="docker container exec -it"
alias nn="docker container run -it --rm -p 6000:6000 -w /app -v $(pwd):/app node bash"
alias dsp="docker system prune --all --volumes"
alias dcu='docker-compose up'
alias dcd='docker-compose down'

# ----------------------------------------------------------------
# tfenv https://github.com/tfutils/tfenv/issues/83
# ----------------------------------------------------------------
alias tfenv='GREP_OPTIONS="--color=never" tfenv'

# ----------------------------------------------------------------
# terraform
# ----------------------------------------------------------------
alias tf="terraform"

# ----------------------------------------------------------------
# tmux
# ----------------------------------------------------------------
alias tt="tmux source-file ~/.tmux.conf && tmux display '🦕: tmux reloaded'"
alias tclean="$HOME/dotfiles/submodules/tpm/bin/clean_plugins"

# ----------------------------------------------------------------
# Tools
# ----------------------------------------------------------------
alias nozo:p="yarn add -D @nozomiishii/prettier-config && echo \"module.exports = { ...require('@nozomiishii/prettier-config') };\" > .prettierrc.js"
