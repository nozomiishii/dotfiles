#!/usr/bin/env bash
#
# pr-title-guard.sh - gh に渡される PR タイトルを repo の commitlint 設定で検証する
# PreToolUse hook。Claude Code (settings.json) と Codex (hooks.json) の両方から呼ぶ。
#
# 判定ルールは持たない。lefthook の commit-msg と同じ nozo-commitlint に流すため、
# 正本は repo の commitlint 設定 (既定は @nozomiishii/commitlint-config) だけになる。
#
# 手元で試すには、PreToolUse の payload を stdin に渡す:
#   printf '{"cwd":"%s","tool_input":{"command":"gh pr create --title \\"docs: x\\""}}' "$PWD" |
#     bash home/.local/bin/pr-title-guard.sh
#
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"

# 全てのシェル呼び出しで発火するため、対象外のコマンドを先に落とす。
case "$cmd" in
  *gh*pr*create* | *gh*pr*edit*) ;;
  *) exit 0 ;;
esac

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty')"
linter="$cwd/node_modules/.bin/nozo-commitlint"
# commitlint を持たない repo には判定材料がないので素通りする。入れ忘れは CI 側で落ちる。
[ -x "$linter" ] || exit 0

# --title=<value> / --title <value> / -t <value> を、先頭のクォートに合わせて取り出す。
extract_title() {
  local rest="$1" value
  if [[ "$rest" =~ --title=(.*) ]]; then
    value="${BASH_REMATCH[1]}"
  elif [[ "$rest" =~ (^|[[:space:]])(--title|-t)[[:space:]]+(.*) ]]; then
    value="${BASH_REMATCH[3]}"
  else
    return 1
  fi

  case "$value" in
    \"*) value="${value#\"}" && value="${value%%\"*}" ;;
    \'*) value="${value#\'}" && value="${value%%\'*}" ;;
    *) value="${value%%[[:space:]]*}" ;;
  esac
  printf '%s' "$value"
}

title="$(extract_title "$cmd")" || exit 0
[ -n "$title" ] || exit 0

result="$(printf '%s' "$title" | "$linter" 2>&1)" && exit 0

# exit 2 で stderr を Claude / Codex に返し、タイトルを直させる。
printf 'PR タイトルが repo の commitlint 設定に違反しています。\n\n%s\n' "$result" >&2
exit 2
