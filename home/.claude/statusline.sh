#!/bin/bash
# Claude Code statusline: model | worktree | diff | context% | cmux surface | cursor link

input=$(cat)

mapfile -t fields < <(jq -r '
  .model.display_name // "Claude",
  .workspace.project_dir // .cwd,
  .workspace.git_worktree // "",
  .worktree.original_branch // "",
  (.context_window.used_percentage // 0 | floor | tostring),
  (.cost.total_lines_added // 0 | tostring),
  (.cost.total_lines_removed // 0 | tostring),
  .cwd
' <<<"$input")

model="${fields[0]}"
project_dir="${fields[1]}"
wt_name="${fields[2]}"
orig_branch="${fields[3]}"
ctx_pct="${fields[4]}"
added="${fields[5]}"
removed="${fields[6]}"
cwd="${fields[7]}"

project=$(basename "$project_dir")

if [[ -n "$wt_name" ]]; then
  loc="${project}[${wt_name}]"
  [[ -n "$orig_branch" ]] && loc="${loc}<-${orig_branch}"
else
  loc="$project"
fi

diff_text=""
if [[ "$added" != "0" || "$removed" != "0" ]]; then
  diff_text="+${added}/-${removed}"
fi

surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null)

esc=$'\033'
st=$'\033\\'
cursor_link="${esc}]8;;cursor://file${cwd}${st}[open]${esc}]8;;${st}"

parts=()
parts+=("${esc}[36m${model}${esc}[0m")
parts+=("${esc}[35m${loc}${esc}[0m")
[[ -n "$diff_text" ]] && parts+=("${esc}[33m${diff_text}${esc}[0m")
parts+=("${esc}[34m${ctx_pct}%${esc}[0m")
[[ -n "$surface_ref" ]] && parts+=("${esc}[32m${surface_ref}${esc}[0m")
parts+=("${esc}[90m${cursor_link}${esc}[0m")

output="${parts[0]}"
for ((i = 1; i < ${#parts[@]}; i++)); do
  output="${output} | ${parts[$i]}"
done

printf '%s' "$output"
