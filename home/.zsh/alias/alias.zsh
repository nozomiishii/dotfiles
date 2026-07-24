# Aliases

# ----------------------------------------------------------------
# NeoVim
# ----------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  alias vi="nvim"
  alias vim="nvim"
fi

# ----------------------------------------------------------------
# Open VS Code
# ----------------------------------------------------------------
alias fj="code ."

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
alias ca="claude agents"
alias cb="claude --bg"
alias cc="claude --continue"
alias cr="claude --resume"
alias crs="claude respawn --all"
alias ct="claude --teleport"
alias cw="claude --worktree"
# プロンプトは stdin で渡す。引数で渡すと worktree 名に流用され 64 字制限で死ぬため
cwb() {
  if [ $# -gt 0 ]; then
    printf '%s' "$*" | claude --worktree --bg
  else
    claude --worktree --bg
  fi
}
alias cwr="claude --worktree --resume"
alias cwt="claude --worktree --teleport"
cpm() { printf "/model claude-opus-4-6[1m]" | pbcopy && echo "Copied: /model claude-opus-4-6[1m]"; }
pwdc() { printf "/add-dir %s" "$PWD" | pbcopy && echo "Copied: /add-dir $PWD"; }

# ----------------------------------------------------------------
# git
# ----------------------------------------------------------------
alias ghb="gh browse"
alias ghp="gh pr view --web"
alias ghpc="gh pr create --assignee @me --web"
alias grmb="git branch --merged|egrep -v '\*|master|main|dev|develop|development|stag|staging|prod|production'|xargs git branch -d && git fetch --prune"
alias gsta="git stash -u"
alias ghv="bunx git-harvest@latest"
alias ghv!="bunx git-harvest@latest --yolo"

# ----------------------------------------------------------------
# nozo
# ----------------------------------------------------------------
alias nozo="pnpx nozo@latest"

# ----------------------------------------------------------------
# Docker
# ----------------------------------------------------------------
alias dsp="docker system prune --all --volumes"

# ----------------------------------------------------------------
# terraform
# ----------------------------------------------------------------
alias tf="terraform"
alias tg="terragrunt"

# ----------------------------------------------------------------
# Raycast
# ----------------------------------------------------------------
# Raycast 設定を export して専用ブランチで PR を作る
alias rbk="$HOME/.config/raycast/scripts/raycast_backup.sh"
