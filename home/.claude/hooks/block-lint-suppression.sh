#!/usr/bin/env bash
# grep の「不一致 = exit 1」を制御フローに使うため -e は付けない
set -uo pipefail

# AGENTS.md「静的解析ルールの抑制禁止」の決定的ガード (PreToolUse / Edit|Write)。
# 抑制コメントの出現数が編集前より増える場合だけ ask にする
# (既存の抑制行の移動・周辺編集は増分ゼロなので発火しない)。
# AGENTS.md は「どうしても必要なときは相談し、承認なしに抑制しない」としており、
# ask のユーザー承認がその手続きに対応する。
suppress_pattern='eslint-disable|@ts-ignore|@ts-expect-error|@ts-nocheck|biome-ignore|prettier-ignore|stylelint-disable|deno-lint-ignore|noqa|type:[[:space:]]*ignore([[:space:]]|\[|$)|nolint|nosec|rubocop:disable|pylint:[[:space:]]*disable|shellcheck[[:space:]]+disable|swiftlint:disable|pragma[[:space:]]+warning[[:space:]]+disable|istanbul[[:space:]]+ignore|c8[[:space:]]+ignore'

input=$(cat)
tool_name=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || exit 0
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")

# ドキュメント類は抑制パターンの「言及」が正当なので対象外
case "$file_path" in
*.md | *.mdx | *.markdown | *.txt) exit 0 ;;
esac

count_suppressions() {
  grep -oiE "$suppress_pattern" <<<"${1:-}" | wc -l | tr -d ' '
}

case "$tool_name" in
Edit)
  new=$(jq -r '.tool_input.new_string // ""' <<<"$input")
  old=$(jq -r '.tool_input.old_string // ""' <<<"$input")
  ;;
Write)
  new=$(jq -r '.tool_input.content // ""' <<<"$input")
  old=""
  if [ -n "$file_path" ] && [ -f "$file_path" ]; then
    old=$(cat "$file_path")
  fi
  ;;
*) exit 0 ;;
esac

if [ "$(count_suppressions "$new")" -gt "$(count_suppressions "$old")" ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask",
    permissionDecisionReason: "静的解析ルールの抑制は禁止 (AGENTS.md)。まずコードを直す。拒否された場合は抑制なしで直す方法を探し、どうしても必要なら理由を添えてユーザーに相談する。"}}'
fi
exit 0
