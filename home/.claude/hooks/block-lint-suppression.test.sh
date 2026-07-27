#!/usr/bin/env bash
# block-lint-suppression.sh のテスト。hook の JSON 入出力契約を検証する。
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$script_dir/block-lint-suppression.sh"
fails=0

decision() { jq -r '.hookSpecificOutput.permissionDecision // "none"'; }

run_edit() {
  jq -n --arg fp "$1" --arg old "$2" --arg new "$3" \
    '{tool_name: "Edit", tool_input: {file_path: $fp, old_string: $old, new_string: $new}}' \
    | bash "$hook"
}

run_write() {
  jq -n --arg fp "$1" --arg content "$2" \
    '{tool_name: "Write", tool_input: {file_path: $fp, content: $content}}' \
    | bash "$hook"
}

# Edit で抑制コメントを新規追加すると ask になる
test_asks_on_new_suppression_in_edit() {
  out=$(run_edit "/tmp/app.ts" "const a = 1;" "// eslint-disable-next-line no-console
const a = 1;")
  [ "$(decision <<<"$out")" = "ask" ]
}

# 既存の抑制行を含むコードの移動 (old にも同数) は通過する
test_allows_moving_existing_suppression() {
  out=$(run_edit "/tmp/app.ts" "// @ts-ignore
const a = 1;" "const b = 2;
// @ts-ignore
const a = 1;")
  [ -z "$out" ]
}

# Write で新規ファイルに抑制コメントを含めると ask になる
test_asks_on_suppression_in_new_file() {
  dir=$(mktemp -d)
  out=$(run_write "$dir/new.py" "x = 1  # noqa: E501")
  rm -rf "$dir"
  [ "$(decision <<<"$out")" = "ask" ]
}

# Write の全文書き換えで既存の抑制を維持するだけなら通過する
test_allows_rewrite_keeping_existing_suppression() {
  dir=$(mktemp -d)
  printf '%s\n' "// eslint-disable-next-line no-console" "console.log(1);" >"$dir/app.js"
  out=$(run_write "$dir/app.js" "// eslint-disable-next-line no-console
console.log(2);")
  rm -rf "$dir"
  [ -z "$out" ]
}

# ドキュメント (.md) での抑制パターンの言及は通過する
test_allows_suppression_mention_in_markdown() {
  out=$(run_edit "/tmp/AGENTS.md" "" "eslint-disable は禁止。")
  [ -z "$out" ]
}

# type: ignoreCase のような前方一致は誤検知しない
test_allows_type_ignore_case_prefix() {
  out=$(run_edit "/tmp/config.ts" "" "const opts = { type: ignoreCase };")
  [ -z "$out" ]
}

run() {
  if "$1"; then echo "ok - $1"; else echo "not ok - $1"; fails=$((fails + 1)); fi
}

run test_asks_on_new_suppression_in_edit
run test_allows_moving_existing_suppression
run test_asks_on_suppression_in_new_file
run test_allows_rewrite_keeping_existing_suppression
run test_allows_suppression_mention_in_markdown
run test_allows_type_ignore_case_prefix
exit "$fails"
