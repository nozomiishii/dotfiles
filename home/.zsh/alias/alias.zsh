# Aliases

# ----------------------------------------------------------------
# NeoVim
# ----------------------------------------------------------------
if command -v nvim >/dev/null 2>&1; then
  alias vi="nvim"
  alias vim="nvim"
fi

# ----------------------------------------------------------------
# Open editors
# ----------------------------------------------------------------
alias fj="cursor ."
alias fjj="code ."

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

# 状態ファイルの置き場。誰でも書ける /tmp に置くと pid ファイルを差し替えられ、
# crc! が任意のプロセスを kill しうる
_crc_state() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-rc"
  mkdir -m 700 -p "$dir" || return 1
  printf '%s\n' "$dir"
}

# pid ファイルから生きている claude の pid を返す
_crc_pid() {
  local pid
  [[ -r $1 ]] || return 1
  pid=$(<"$1")
  # 数値以外と、pid 再利用で別プロセスになったものを弾く
  [[ $pid == <-> ]] || return 1
  [[ $(ps -o comm= -p "$pid" 2>/dev/null) == *claude* ]] || return 1
  printf '%s\n' "$pid"
}

# ~/Code/nozomiishii の全 repo で Remote Control サーバーを起動する。スマホの Code タブから繋ぐ用。
# 各 repo で 1 回は対話で claude を起動し、workspace trust を承認しておく
# https://code.claude.com/docs/en/remote-control#requirements
crc() {
  local state dir name
  state=$(_crc_state) || return 1

  for dir in "$HOME/Code/nozomiishii"/*(/N); do
    [[ -e $dir/.git ]] || continue
    name=${dir:t}

    if _crc_pid "$state/$name.pid" >/dev/null; then
      echo "skip  $name"
      continue
    fi

    # nohup でターミナルを閉じても落ちないようにする。再起動・ログアウトでは消える
    (
      cd "$dir" || exit
      nohup claude remote-control --name "$name" >"$state/$name.log" 2>&1 </dev/null &
      printf '%s\n' "$!" >"$state/$name.pid"
    )
    echo "start $name"
  done
}

# crc で起動したサーバーを全部止める
crc!() {
  local state pidfile pid
  state=$(_crc_state) || return 1

  for pidfile in "$state"/*.pid(N); do
    pid=$(_crc_pid "$pidfile") && kill "$pid"
    rm -f "$pidfile"
  done
}

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
