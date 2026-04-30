#!/usr/bin/env bash
set -uo pipefail

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

# --- input parsing ---

input=$(cat)

fields=()
while IFS= read -r line; do
  fields+=("$line")
done < <(jq -r '
  .model.display_name // "Claude",
  (.context_window.used_percentage // 0 | floor | tostring),
  .cwd // ""
' <<<"$input")

model="${fields[0]:-Claude}"
ctx_pct="${fields[1]:-0}"
cwd="${fields[2]:-$HOME}"

# cmux が無い環境では fork ごと省略
surface_ref=""
if command -v cmux >/dev/null 2>&1; then
  surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null || true)
fi

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
urlencode() {
  local s="$1"
  local out="" i char
  local LC_ALL=C
  for ((i = 0; i < ${#s}; i++)); do
    char="${s:$i:1}"
    case "$char" in
      [a-zA-Z0-9._~/-]) out+="$char" ;;
      *)
        printf -v char '%%%02X' "'$char"
        out+="$char"
        ;;
    esac
  done
  printf '%s' "$out"
}

# starship は CWD 依存なので subshell で cd してから呼ぶ。
# subshell 終了で親プロセスの PWD には漏れない。
starship_at() {
  (
    cd "$cwd" 2>/dev/null || exit 0
    STARSHIP_CONFIG="$HOME/.config/starship/starship.toml" starship "$@" 2>/dev/null
  )
}

# OSC 8 hyperlink で cwd を Cursor で開ける `[editor]` リンクを返す。
build_cursor_link() {
  local url
  url="cursor://file$(urlencode "$cwd")"
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
    local abs_common repo_name wt_dir diff_text
    abs_common=$(cd "$cwd" 2>/dev/null && cd "$git_common" 2>/dev/null && pwd)
    repo_name=$(basename "$(dirname "$abs_common")")
    wt_dir=$(basename "$wt_top")
    diff_text=$(starship_at module git_status | sed 's/ *$//')

    local parts=("${cyan}${repo_name}${reset}" "${green}worktree:(${red}${wt_dir}${reset}${green})${reset}")
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
  parts+=("${yellow}${ctx_pct}%${reset}")
  [[ -n "$surface_ref" ]] && parts+=("${blue}${surface_ref}${reset}")
  parts+=("${gray}$(build_cursor_link)${reset}")
  join ' | ' "${parts[@]}"
}

# --- output ---

# cwd が消えた場合（git worktree remove 等）は警告のみ表示して env_line は維持
if [[ ! -d "$cwd" ]]; then
  printf '%s(stale cwd: %s)%s\n%s' "$red" "$cwd" "$reset" "$(render_env_line)"
  exit 0
fi

printf '%s\n%s' "$(render_top_line)" "$(render_env_line)"
