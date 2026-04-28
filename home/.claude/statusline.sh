#!/usr/bin/env bash
# Claude Code statusline: model | cwd | git:(branch) | +N -N | ctx% | cmux | [editor]
# starship 風の表記スタイルに合わせた構成

input=$(cat)

# mapfile is bash 4+. /bin/bash on macOS is 3.2 — read in a loop instead.
fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(jq -r '
  .model.display_name // "Claude",
  (.context_window.used_percentage // 0 | floor | tostring),
  (.cost.total_lines_added // 0 | tostring),
  (.cost.total_lines_removed // 0 | tostring),
  .cwd,
  .worktree.branch // "",
  .workspace.project_dir // ""
' <<<"$input")

model="${fields[0]}"
ctx_pct="${fields[1]}"
added="${fields[2]}"
removed="${fields[3]}"
cwd="${fields[4]}"
branch_from_json="${fields[5]}"
project_dir="${fields[6]}"

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
[[ "$added" != "0" ]] && diff_text="+${added}"
if [[ "$removed" != "0" ]]; then
  [[ -n "$diff_text" ]] && diff_text="${diff_text} "
  diff_text="${diff_text}-${removed}"
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
gray="${esc}[90m"

cwd_url="$cwd"
cwd_url="${cwd_url//%/%25}"
cwd_url="${cwd_url// /%20}"
cwd_url="${cwd_url//\#/%23}"
cwd_url="${cwd_url//\?/%3F}"
cursor_link="${esc}]8;;cursor://file${cwd_url}${st}[editor]${esc}]8;;${st}"

git_parts=()
git_parts+=("${cyan}${loc}${reset}")
[[ -n "$branch" ]] && git_parts+=("${blue}git:(${red}${branch}${reset}${blue})${reset}")
[[ -n "$diff_text" ]] && git_parts+=("${yellow}${diff_text}${reset}")

env_parts=()
env_parts+=("${magenta}${model}${reset}")
env_parts+=("${yellow}${ctx_pct}%${reset}")
[[ -n "$surface_ref" ]] && env_parts+=("${green}${surface_ref}${reset}")
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

printf '%s\n%s' "$(join ' ' "${git_parts[@]}")" "$(join ' | ' "${env_parts[@]}")"
