#!/usr/bin/env bash
set -uo pipefail

# --- colors ---

# 命名規則: <color> は non-bold、<color>_bold は bold 版。
esc=$'\033'
st=$'\033\\'
reset="${esc}[0m"
red_bold="${esc}[1;31m"
green_bold="${esc}[1;32m"
yellow="${esc}[33m"
yellow_bold="${esc}[1;33m"
blue_bold="${esc}[1;34m"
white="${esc}[37m"
cyan_bold="${esc}[1;36m"
gray="${esc}[38;5;250m"

# --- input parsing ---

input=$(cat)

fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(jq -r '
  .model.display_name // "Claude",
  (.context_window.used_percentage // 0 | floor | tostring),
  .cwd // "",
  .workspace.project_dir // .cwd // "",
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then "" else floor | tostring end),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then "" else floor | tostring end),
  (.rate_limits.five_hour.resets_at // "" | tostring),
  (.rate_limits.seven_day.resets_at // "" | tostring)
' <<<"$input")

model="${fields[0]:-Claude}"
ctx_pct="${fields[1]:-0}"
cwd="${fields[2]:-$HOME}"
# project_dir は claude 起動時に固定。cwd は /add-dir や cd で動的に変わり、
# worktree 削除時は Claude Code 側で別ディレクトリに自動 recover されるため、
# stale 判定には fixed な project_dir を使う。
project_dir="${fields[3]:-$cwd}"
# 5h / 7d rate limit は Claude.ai 購読者のみ、最初の API 応答後に出現する。
# 未取得の間は空文字で、env_line では該当パートを省略する。
five_hour_pct="${fields[4]:-}"
seven_day_pct="${fields[5]:-}"
five_hour_resets_at="${fields[6]:-}"
seven_day_resets_at="${fields[7]:-}"

# cmux が無い環境では fork ごと省略
surface_ref=""
# if command -v cmux >/dev/null 2>&1; then
#   surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null || true)
# fi

# --- helpers ---

join() {
  local sep="$1"
  shift
  (($# == 0)) && return
  local out="$1"
  shift
  local p
  for p in "$@"; do
    out="${out}${sep}${p}"
  done
  printf '%s' "$out"
}

# RFC 3986 unreserved + / 以外を percent-encode する。
# LC_ALL=C で UTF-8 マルチバイト文字を byte 単位で正しくエンコード。
# `~` は技術的には unreserved だが、Cursor の URL handler がパス内の `~` を
# ホーム展開等で誤解釈し ~/Library/Mobile Documents/iCloud~md~obsidian/...
# 配下を開けないため、明示的に %7E にエスケープする。
urlencode() {
  local s="$1"
  local out="" i char
  local LC_ALL=C
  for ((i = 0; i < ${#s}; i++)); do
    char="${s:$i:1}"
    case "$char" in
      [a-zA-Z0-9._/-]) out+="$char" ;;
      *)
        printf -v char '%%%02X' "'$char"
        out+="$char"
        ;;
    esac
  done
  printf '%s' "$out"
}

format_remaining() {
  local resets_at="$1"
  [[ -z "$resets_at" ]] && return
  local now remaining_sec days hours minutes
  now=$(date +%s)
  remaining_sec=$((resets_at - now))
  ((remaining_sec <= 0)) && { printf '0m'; return; }
  days=$((remaining_sec / 86400))
  hours=$(( (remaining_sec % 86400) / 3600 ))
  minutes=$(( (remaining_sec % 3600) / 60 ))
  if ((days > 0)); then
    printf '%dd%dh' "$days" "$hours"
  elif ((hours > 0)); then
    printf '%dh%02dm' "$hours" "$minutes"
  else
    printf '%dm' "$minutes"
  fi
}

# starship は CWD 依存なので subshell で cd してから呼ぶ。
# subshell 終了で親プロセスの PWD には漏れない。
starship_at() {
  (
    cd "$cwd" 2>/dev/null || exit 0
    STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" starship "$@" 2>/dev/null
  )
}

# OSC 8 hyperlink で cwd を VS Code で開ける `[editor]` リンクを返す。
build_editor_link() {
  local url
  url="vscode://file$(urlencode "$cwd")"
  printf '%s]8;;%s%s[editor]%s]8;;%s' "$esc" "$url" "$st" "$esc" "$st"
}

# --- renderers ---

# 1行目: worktree内ならカスタム表示、それ以外は starship prompt に丸投げ。
render_top_line() {
  local git_dir="" git_common="" wt_top=""
  {
    IFS= read -r git_dir
    IFS= read -r git_common
    IFS= read -r wt_top
  } < <(git -C "$cwd" rev-parse --git-dir --git-common-dir --show-toplevel 2>/dev/null || true)

  if [[ "$git_dir" == */worktrees/* ]]; then
    local abs_common repo_name wt_dir diff_text branch
    abs_common=$(cd "$cwd" 2>/dev/null && cd "$git_common" 2>/dev/null && pwd)
    repo_name=$(basename "$(dirname "$abs_common")")
    wt_dir=$(basename "$wt_top")
    diff_text=$(starship_at module git_status | sed 's/ *$//')
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

    local parts=("${cyan_bold}${repo_name}${reset}" "${green_bold}worktree:(${red_bold}${wt_dir}${reset}${green_bold})${reset}")
    # claude -w 自動生成は branch = worktree-{wt_dir} で情報重複するので省略。
    # 手動で別ブランチを切った worktree のときだけ git:() を追加。
    if [[ -n "$branch" && "$branch" != "worktree-${wt_dir}" ]]; then
      parts+=("${blue_bold}git:(${red_bold}${branch}${reset}${blue_bold})${reset}")
    fi
    [[ -n "$diff_text" ]] && parts+=("$diff_text")
    join ' ' "${parts[@]}"
    return
  fi

  # starship prompt は 2 行構成 ($directory ... $line_break $character) なので
  # 1 行目 (cwd 行) のみを採用。2 行目の `→` は statusline には不要。
  # 親シェル (zsh) から STARSHIP_SHELL が継承されると starship が zsh モードで
  # %{ ... %} (zero-width マーカー) を埋め込むが、Claude statusline では
  # 解釈されずリテラル表示されてしまうため sed で除去する。
  starship_at prompt --terminal-width=120 | head -1 | sed 's/%[{}]//g'
}

render_env_line() {
  local parts=()
  parts+=("${white}${model}${reset}")
  parts+=("${yellow_bold}${ctx_pct}%${reset}")
  if [[ -n "$five_hour_pct" ]]; then
    local h_remaining
    h_remaining=$(format_remaining "$five_hour_resets_at")
    if [[ -n "$h_remaining" ]]; then
      parts+=("${yellow}h ${five_hour_pct}% (${h_remaining})${reset}")
    else
      parts+=("${yellow}h ${five_hour_pct}%${reset}")
    fi
  fi
  if [[ -n "$seven_day_pct" ]]; then
    local w_remaining
    w_remaining=$(format_remaining "$seven_day_resets_at")
    if [[ -n "$w_remaining" ]]; then
      parts+=("${yellow}w ${seven_day_pct}% (${w_remaining})${reset}")
    else
      parts+=("${yellow}w ${seven_day_pct}%${reset}")
    fi
  fi
  [[ -n "$surface_ref" ]] && parts+=("${blue_bold}${surface_ref}${reset}")
  parts+=("${gray}$(build_editor_link)${reset}")
  join ' | ' "${parts[@]}"
}

# --- output ---

# project_dir (claude 起動時の固定 cwd) が消えた場合 (git worktree remove 等)
# は警告のみ表示して env_line は維持。cwd は recover されるためここでは見ない。
if [[ ! -d "$project_dir" ]]; then
  printf '%s(stale project_dir: %s)%s\n%s' "$red_bold" "$project_dir" "$reset" "$(render_env_line)"
  exit 0
fi

printf '%s\n%s' "$(render_top_line)" "$(render_env_line)"
