#!/usr/bin/env bash

# --- helpers ---

join() {
  local sep="$1"
  shift
  local out="$1"
  shift
  local p
  for p in "$@"; do
    out="${out}${sep}${p}"
  done
  printf '%s' "$out"
}

urlencode() {
  local s="$1"
  s="${s//%/%25}"
  s="${s// /%20}"
  s="${s//\#/%23}"
  s="${s//\?/%3F}"
  printf '%s' "$s"
}

starship_at() {
  STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" starship "$@" 2>/dev/null
}

# --- input parsing ---

input=$(cat)

fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(jq -r '
  .model.display_name // "Claude",
  (.context_window.used_percentage // 0 | floor | tostring),
  .cwd
' <<<"$input")

model="${fields[0]}"
ctx_pct="${fields[1]}"
cwd="${fields[2]}"

cd "$cwd" 2>/dev/null

# cmux が無い環境では fork ごと省略
surface_ref=""
if command -v cmux >/dev/null 2>&1; then
  surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null)
fi

# --- colors ---

esc=$'\033'
st=$'\033\\'
reset="${esc}[0m"
red="${esc}[1;31m"
green="${esc}[1;32m"
yellow="${esc}[1;33m"
blue="${esc}[1;34m"
white="${esc}[37m"
cyan="${esc}[1;36m"
gray="${esc}[38;5;250m"

# --- cursor link ---

cursor_url="cursor://file$(urlencode "$cwd")"
cursor_link="${esc}]8;;${cursor_url}${st}[editor]${esc}]8;;${st}"

# --- renderers ---

# 1行目: worktree内ならカスタム表示、それ以外は starship prompt に丸投げ。
# 末尾 extras は両ブランチで append される拡張点。
render_top_line() {
  local extras=("$@")
  local git_dir="" git_common="" wt_top=""
  {
    IFS= read -r git_dir
    IFS= read -r git_common
    IFS= read -r wt_top
  } < <(git rev-parse --git-dir --git-common-dir --show-toplevel 2>/dev/null)

  local parts=()
  if [[ "$git_dir" == */worktrees/* ]]; then
    local abs_common repo_name wt_dir diff_text
    abs_common=$(cd "$git_common" 2>/dev/null && pwd)
    repo_name=$(basename "$(dirname "$abs_common")")
    wt_dir=$(basename "$wt_top")
    diff_text=$(starship_at module git_status | sed 's/ *$//')

    parts=("${cyan}${repo_name}${reset}" "${green}worktree:(${red}${wt_dir}${reset}${green})${reset}")
    [[ -n "$diff_text" ]] && parts+=("$diff_text")
  else
    # starship prompt の先頭行のみ採用し、zsh のプロンプトエスケープ %{ %} を除去
    local prompt
    prompt=$(starship_at prompt --terminal-width=120 | head -1 | sed 's/%[{}]//g')
    parts=("$prompt")
  fi

  parts+=("${extras[@]}")
  join ' ' "${parts[@]}"
}

render_env_line() {
  local parts=()
  parts+=("${white}${model}${reset}")
  parts+=("${yellow}${ctx_pct}%${reset}")
  [[ -n "$surface_ref" ]] && parts+=("${blue}${surface_ref}${reset}")
  parts+=("${gray}${cursor_link}${reset}")
  join ' | ' "${parts[@]}"
}

# --- output ---

top_extras=()
printf '%s\n%s' "$(render_top_line "${top_extras[@]}")" "$(render_env_line)"
