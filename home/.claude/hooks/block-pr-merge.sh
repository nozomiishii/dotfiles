#!/usr/bin/env bash
set -uo pipefail

# PR マージ操作の決定的ガード (PreToolUse / Bash)。PR のマージはユーザーが行う。
#
# permissions.deny の "Bash(gh pr merge:*)" は先頭一致のため、
# `cd x && gh pr merge` や `bash -c "gh pr merge"` のような複合・間接実行を
# 防げない。この hook はコマンド文字列全体をスキャンして deny する。
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null) || exit 0
[ -z "$cmd" ] && exit 0

# 行頭・区切り記号・引用符の直後の gh pr merge (間接・複合実行を含む)
gh_pr_merge="(^|[;&|[:space:]\`(\"'])gh[[:space:]]+pr[[:space:]]+merge([[:space:]\"']|\$)"
# gh api の REST merge エンドポイント
rest_merge="repos/[^[:space:]]+/pulls/[^[:space:]]+/merge"
# graphql のマージ系 mutation (auto-merge 予約も勝手なマージに含める)
graphql_merge="mergePullRequest|enablePullRequestAutoMerge"

if grep -qE "$gh_pr_merge" <<<"$cmd" \
  || grep -qE "$rest_merge" <<<"$cmd" \
  || grep -qE "$graphql_merge" <<<"$cmd"; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
    permissionDecisionReason: "PR のマージはユーザーが行う。マージはせず、PR の URL とマージ可能な状態を報告してユーザーに依頼する。"}}'
fi
exit 0
