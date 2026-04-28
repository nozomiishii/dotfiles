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
cursor_link="${esc}]8;;cursor://file${cwd}${st}[editor]${esc}]8;;${st}"

git_parts=()
git_parts+=("${esc}[1;36m${loc}${esc}[0m")
[[ -n "$branch" ]] && git_parts+=("${esc}[1;34mgit:(${esc}[1;31m${branch}${esc}[0m${esc}[1;34m)${esc}[0m")
[[ -n "$diff_text" ]] && git_parts+=("${esc}[1;33m${diff_text}${esc}[0m")

env_parts=()
env_parts+=("${esc}[1;35m${model}${esc}[0m")
env_parts+=("${esc}[1;33m${ctx_pct}%${esc}[0m")
[[ -n "$surface_ref" ]] && env_parts+=("${esc}[1;32m${surface_ref}${esc}[0m")
env_parts+=("${esc}[90m${cursor_link}${esc}[0m")

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
