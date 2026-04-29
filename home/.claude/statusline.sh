#!/usr/bin/env bash

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

surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null)

esc=$'\033'
st=$'\033\\'
reset="${esc}[0m"
red="${esc}[1;31m"
green="${esc}[1;32m"
yellow="${esc}[1;33m"
blue="${esc}[1;34m"
magenta="${esc}[1;35m"
cyan="${esc}[1;36m"
gray="${esc}[38;5;250m"

cwd_url="$cwd"
cwd_url="${cwd_url//%/%25}"
cwd_url="${cwd_url// /%20}"
cwd_url="${cwd_url//\#/%23}"
cwd_url="${cwd_url//\?/%3F}"
cursor_url="cursor://file${cwd_url}"
cursor_link="${esc}]8;;${cursor_url}${st}[editor]${esc}]8;;${st}"

# 1行目: worktree内ならカスタム表示、それ以外は starship に丸投げ
git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
if [[ "$git_dir" == */worktrees/* ]]; then
  common=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
  abs_common=$(cd "$cwd" 2>/dev/null && cd "$common" 2>/dev/null && pwd)
  repo_name=$(basename "$(dirname "$abs_common")")
  wt_top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  wt_dir=$(basename "$wt_top")

  diff_text=""
  porcelain=$(git -C "$cwd" status --porcelain=v1 2>/dev/null)
  if [[ -n "$porcelain" ]]; then
    staged=$(grep -c '^[MADRC]' <<<"$porcelain")
    modified=$(grep -c '^.[MD]' <<<"$porcelain")
    untracked=$(grep -c '^??' <<<"$porcelain")
    diff_parts=()
    ((staged > 0)) && diff_parts+=("+${staged}")
    ((modified > 0)) && diff_parts+=("!${modified}")
    ((untracked > 0)) && diff_parts+=("?${untracked}")
    diff_text="${diff_parts[*]}"
  fi

  parts=("${cyan}${repo_name}${reset}" "${green}worktree:(${red}${wt_dir}${reset}${green})${reset}")
  [[ -n "$diff_text" ]] && parts+=("${yellow}${diff_text}${reset}")
  IFS=' '
  top_line="${parts[*]}"
  unset IFS
else
  top_line=$(cd "$cwd" 2>/dev/null \
    && STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" \
       starship prompt --terminal-width=120 2>/dev/null \
    | head -1 | sed 's/%[{}]//g')
fi

env_parts=()
env_parts+=("${magenta}${model}${reset}")
env_parts+=("${yellow}${ctx_pct}%${reset}")
[[ -n "$surface_ref" ]] && env_parts+=("${blue}${surface_ref}${reset}")
env_parts+=("${gray}${cursor_link}${reset}")

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

printf '%s\n%s' "${top_line}" "$(join ' | ' "${env_parts[@]}")"
