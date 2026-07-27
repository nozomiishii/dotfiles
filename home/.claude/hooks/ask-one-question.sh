#!/usr/bin/env bash
set -uo pipefail

# AGENTS.md「質問は1つずつする」の決定的ガード (PreToolUse / AskUserQuestion)。
# questions が 2 件以上なら deny し、モデルに 1 問へ絞り直させる。
# 1 質問内の選択肢 (options) が複数あるのは正常系なので見ない。
# 判定不能・入力欠損は通す。
input=$(cat)
count=$(jq '.tool_input.questions // [] | length' <<<"$input" 2>/dev/null) || exit 0

if [ "$count" -gt 1 ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
    permissionDecisionReason: "質問は1つずつ (AGENTS.md)。最も重要な1問に絞って出し直し、残りは回答後に聞く。"}}'
fi
exit 0
