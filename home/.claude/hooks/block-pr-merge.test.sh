#!/usr/bin/env bash
# block-pr-merge.sh のテスト。hook の JSON 入出力契約を検証する。
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$script_dir/block-pr-merge.sh"
fails=0

decision() { jq -r '.hookSpecificOutput.permissionDecision // "none"'; }

run_hook() {
  jq -n --arg cmd "$1" '{tool_name: "Bash", tool_input: {command: $cmd}}' | bash "$hook"
}

# gh pr merge の直接実行は deny される
test_denies_gh_pr_merge() {
  [ "$(run_hook 'gh pr merge 123' | decision)" = "deny" ]
}

# 複合コマンド内の gh pr merge も deny される
test_denies_compound_command() {
  [ "$(run_hook 'cd ~/Code/nozomiishii/dotfiles && gh pr merge 123 --squash' | decision)" = "deny" ]
}

# bash -c 経由の間接実行も deny される
test_denies_indirect_execution() {
  [ "$(run_hook 'bash -c "gh pr merge 123"' | decision)" = "deny" ]
}

# gh api の REST merge エンドポイントは deny される
test_denies_rest_merge_endpoint() {
  [ "$(run_hook 'gh api -X PUT repos/nozomiishii/dotfiles/pulls/123/merge' | decision)" = "deny" ]
}

# graphql の mergePullRequest mutation は deny される
test_denies_graphql_merge_mutation() {
  [ "$(run_hook 'gh api graphql -f query="mutation { mergePullRequest(input: {pullRequestId: \"x\"}) { clientMutationId } }"' | decision)" = "deny" ]
}

# graphql の auto-merge 有効化 (マージ予約) は deny される
test_denies_graphql_auto_merge() {
  [ "$(run_hook 'gh api graphql -f query="mutation { enablePullRequestAutoMerge(input: {pullRequestId: \"x\"}) { clientMutationId } }"' | decision)" = "deny" ]
}

# gh pr view は通過する
test_allows_gh_pr_view() {
  out=$(run_hook 'gh pr view 123')
  [ -z "$out" ]
}

# ローカルの git merge は通過する
test_allows_git_merge() {
  out=$(run_hook 'git merge main')
  [ -z "$out" ]
}

# command が無い入力は通過する
test_allows_missing_command() {
  out=$(printf '%s' '{"tool_name":"Bash","tool_input":{}}' | bash "$hook")
  [ -z "$out" ]
}

run() {
  if "$1"; then echo "ok - $1"; else echo "not ok - $1"; fails=$((fails + 1)); fi
}

run test_denies_gh_pr_merge
run test_denies_compound_command
run test_denies_indirect_execution
run test_denies_rest_merge_endpoint
run test_denies_graphql_merge_mutation
run test_denies_graphql_auto_merge
run test_allows_gh_pr_view
run test_allows_git_merge
run test_allows_missing_command
exit "$fails"
