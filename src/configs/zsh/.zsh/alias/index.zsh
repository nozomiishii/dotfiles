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

if command -v eza > /dev/null 2>&1; then
  alias ls="eza"
  alias ll="eza -laFh --git"
fi

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------
source "$HOME/.zsh/alias/git.zsh"
alias ghb="gh browse"
alias ghp="gh pr view --web"
alias grmb="git branch --merged|egrep -v '\*|master|main|dev|develop|development|stag|staging|prod|production'|xargs git branch -d && git fetch --prune"

# ----------------------------------------------------------------
# npm
# ----------------------------------------------------------------
alias prisma="npx prisma"
alias yul="yarn upgrade --latest"
alias p='pnpm'

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
alias nozo:l="npx -y @nozomiishii/lefthook-config@latest"
alias nozo:p="npx -y @nozomiishii/prettier-config@latest"
alias nozo:e="npx -y @nozomiishii/eslint-config@latest"
alias nozo:i="nozo:p && nozo:e && mv postcss.config.js postcss.config.cjs"
#

# https://code-maven.com/display-notification-from-the-mac-command-line
alias ding="osascript -e 'display alert \"🧙🏿‍♂️ ding!\"' > /dev/null 2>&1; open -a iTerm.app"

alias noa="(dev && pnpm -F bots start noa --headed)"