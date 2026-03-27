# Aliases

# ----------------------------------------------------------------
# NeoVim
# ----------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  alias vi="nvim"
  alias vim="nvim"
fi

# ----------------------------------------------------------------
# Open Cursor
# ----------------------------------------------------------------
alias fj="cursor ."

# ----------------------------------------------------------------
# shell
# ----------------------------------------------------------------
alias rr="exec $SHELL"

if command -v eza >/dev/null 2>&1; then
  alias ls="eza --group-directories-first"
  alias ll="eza --group-directories-first --all --long --header --git"
fi

# ----------------------------------------------------------------
# zellij
# ----------------------------------------------------------------
alias z="zellij"
alias zz="zellij attach code"
z!() {
  # 除外したいセッション名をここに列挙（スペース区切り）
  local keep_sessions=("code" "web")

  # 配列から正規表現を作成：^(code|web|foo)$ のように変換
  local pattern="^($(
    IFS='|'
    echo "${keep_sessions[*]}"
  ))$"

  # 一致しないセッションを削除
  zellij list-sessions --short | grep -Ev "$pattern" | xargs -r -n1 zellij delete-session --force
}
# ----------------------------------------------------------------
# claude
# ----------------------------------------------------------------
alias c="claude"
alias cr="claude --resume"
alias ct="claude --teleport"
alias cw="claude --worktree"

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------
alias ghb="gh browse"
alias ghp="gh pr view --web"
alias ghpc="gh pr create --assignee @me --web"
alias grmb="git branch --merged|egrep -v '\*|master|main|dev|develop|development|stag|staging|prod|production'|xargs git branch -d && git fetch --prune"
alias gsta="git stash -u"

# ----------------------------------------------------------------
# Docker
# ----------------------------------------------------------------
alias dsp="docker system prune --all --volumes"

# ----------------------------------------------------------------
# terraform
# ----------------------------------------------------------------
alias tf="terraform"
alias tg="terragrunt"
