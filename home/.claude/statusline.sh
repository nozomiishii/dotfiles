#!/usr/bin/env bash

input=$(cat)

fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(jq -r '
  .model.display_name // "Claude",
  (.context_window.used_percentage // 0 | floor | tostring),
  .cwd,
  .worktree.branch // "",
  .workspace.project_dir // ""
' <<<"$input")

model="${fields[0]}"
ctx_pct="${fields[1]}"
cwd="${fields[2]}"
branch_from_json="${fields[3]}"
project_dir="${fields[4]}"

root=$(basename "${project_dir:-$cwd}")
leaf=$(basename "$cwd")
if [[ -z "$leaf" || "$root" == "$leaf" ]]; then
  loc="$root"
else
  loc="${root}[${leaf}]"
fi

if [[ -n "$branch_from_json" ]]; then
  branch="$branch_from_json"
else
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

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
white="${esc}[1;37m"
underline="${esc}[4m"

cwd_url="$cwd"
cwd_url="${cwd_url//%/%25}"
cwd_url="${cwd_url// /%20}"
cwd_url="${cwd_url//\#/%23}"
cwd_url="${cwd_url//\?/%3F}"
cursor_url="cursor://file${cwd_url}"

cursor_line="${white}${underline}${cursor_url}${reset}"

git_parts=()
git_parts+=("${cyan}${loc}${reset}")
[[ -n "$branch" ]] && git_parts+=("${blue}git:(${red}${branch}${reset}${blue})${reset}")
[[ -n "$diff_text" ]] && git_parts+=("${yellow}${diff_text}${reset}")

env_parts=()
env_parts+=("${magenta}${model}${reset}")
env_parts+=("${yellow}${ctx_pct}%${reset}")
[[ -n "$surface_ref" ]] && env_parts+=("${green}${surface_ref}${reset}")

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

printf '%s\n%s\n%s' "$cursor_line" "$(join ' ' "${git_parts[@]}")" "$(join ' | ' "${env_parts[@]}")"
