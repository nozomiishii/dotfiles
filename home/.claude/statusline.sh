#!/bin/bash
# Claude Code statusline: model | cwd | git:(branch) | +N -N | ctx% | cmux | [editor]
# starship 風の表記スタイルに合わせた構成

input=$(cat)

mapfile -t fields < <(jq -r '
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
c_dir="${esc}[1;36m"
c_git="${esc}[1;34m"
c_branch="${esc}[1;31m"
c_diff="${esc}[1;33m"
c_model="${esc}[1;35m"
c_ctx="${esc}[1;33m"
c_surface="${esc}[1;32m"
c_link="${esc}[90m"

cursor_link="${esc}]8;;cursor://file${cwd}${st}[editor]${esc}]8;;${st}"

git_parts=()
git_parts+=("${c_dir}${loc}${reset}")
[[ -n "$branch" ]] && git_parts+=("${c_git}git:(${c_branch}${branch}${reset}${c_git})${reset}")
[[ -n "$diff_text" ]] && git_parts+=("${c_diff}${diff_text}${reset}")

env_parts=()
env_parts+=("${c_model}${model}${reset}")
env_parts+=("${c_ctx}${ctx_pct}%${reset}")
[[ -n "$surface_ref" ]] && env_parts+=("${c_surface}${surface_ref}${reset}")
env_parts+=("${c_link}${cursor_link}${reset}")

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
