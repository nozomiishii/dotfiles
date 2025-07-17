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
fi

# ----------------------------------------------------------------
# Open VScode
# ----------------------------------------------------------------
# alias fj="code ."

# ----------------------------------------------------------------
# Open Cursor
# ----------------------------------------------------------------
alias fj="cursor ."

# ----------------------------------------------------------------
# Restart Raycast
# ----------------------------------------------------------------
alias restart_raycast='osascript -e '\''quit app "Raycast"'\'' && sleep 2 && open -a "Raycast"'

# ----------------------------------------------------------------
# Change Directory
# ----------------------------------------------------------------
alias dsk="cd ~/Desktop"
alias plist="cd ~/Library/Preferences"

alias dot="cd $HOME/dotfiles"
alias noz="cd $CODE_DIR/nozomiishii"
alias dev="cd $CODE_DIR/nozomiishii/dev"
alias arc="cd $CODE_DIR/nozomiishii/archives"
alias repo="cd $CODE_DIR"

# ----------------------------------------------------------------
# shell
# ----------------------------------------------------------------
alias rr="exec $SHELL"

if command -v eza > /dev/null 2>&1; then
  alias ls="eza --group-directories-first"
  alias ll="eza --group-directories-first --all --long --header --git"
fi

# ----------------------------------------------------------------
# zellij
# ----------------------------------------------------------------
alias z="zellij"
alias z3="zellij --layout $HOME/.config/zellij/layouts/pane3.kdl"

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------
alias ghb="gh browse"
alias ghp="gh pr view --web"
alias ghpc="gh pr create --assignee @me --web"
alias grmb="git branch --merged|egrep -v '\*|master|main|dev|develop|development|stag|staging|prod|production'|xargs git branch -d && git fetch --prune"
alias gsta="git stash -u"

# ----------------------------------------------------------------
# pnpm
# ----------------------------------------------------------------
alias p='pnpm'
alias pi='pnpm install'
alias npm='pnpm'
alias npx='pnpx'
alias yarn='pnpm'

# ----------------------------------------------------------------
# nextjs
# ----------------------------------------------------------------
alias nextjs="pnpx create-next-app@latest --typescript --tailwind --eslint --app --src-dir --no-turbopack --use-pnpm"

# ----------------------------------------------------------------
# Playwright
# ----------------------------------------------------------------
alias pwr="npx playwright show-report"

# ----------------------------------------------------------------
# network
# ----------------------------------------------------------------
alias wifi="networksetup -setairportpower en0 off && networksetup -setairportpower en0 on"

# ----------------------------------------------------------------
# Docker
# ----------------------------------------------------------------
alias dsp="docker system prune --all --volumes"

# ----------------------------------------------------------------
# Tools
# ----------------------------------------------------------------
alias nozo:l="npx -y @nozomiishii/lefthook-config@latest"
alias nozo:p="npx -y @nozomiishii/prettier-config@latest"
alias nozo:e="npx -y @nozomiishii/eslint-config@latest"
alias nozo:i="nozo:p && nozo:e && mv postcss.config.js postcss.config.cjs"

# ----------------------------------------------------------------
# Workflow
# ----------------------------------------------------------------
alias noa="(dev && pnpm -F bots start noa --headed)"
