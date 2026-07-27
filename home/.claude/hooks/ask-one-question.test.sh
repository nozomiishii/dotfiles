#!/usr/bin/env bash
# ask-one-question.sh のテスト。hook の JSON 入出力契約を検証する。
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$script_dir/ask-one-question.sh"
fails=0

decision() { jq -r '.hookSpecificOutput.permissionDecision // "none"'; }

# 2 問以上の AskUserQuestion は deny される
test_denies_multiple_questions() {
  out=$(printf '%s' '{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"a"},{"question":"b"}]}}' | bash "$hook")
  [ "$(decision <<<"$out")" = "deny" ]
}

# 1 問なら出力なしで通過する
test_allows_single_question() {
  out=$(printf '%s' '{"tool_name":"AskUserQuestion","tool_input":{"questions":[{"question":"a"}]}}' | bash "$hook")
  [ -z "$out" ]
}

# questions が無い入力は通過する (スキーマ変化への耐性)
test_allows_missing_questions() {
  out=$(printf '%s' '{"tool_name":"AskUserQuestion","tool_input":{}}' | bash "$hook")
  [ -z "$out" ]
}

run() {
  if "$1"; then echo "ok - $1"; else echo "not ok - $1"; fails=$((fails + 1)); fi
}

run test_denies_multiple_questions
run test_allows_single_question
run test_allows_missing_questions
exit "$fails"
