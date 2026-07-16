#!/usr/bin/env bash
set -euo pipefail

# git push の直前に積みコミット一覧をモデルへ注入する PreToolUse Hook
#
# 同一セッションで複数タスクを続けると、別タスクのコミットが同じセッション
# ブランチに積まれたまま push され、PR に無関係な変更として混入することがある:
# https://github.com/nozomiishii/dotfiles/pull/1327
# 「タスクと無関係か」は機械判定できないため、ブロックはせず、push される
# コミット一覧を additionalContext で必ずモデルの目に入れて判断させる。

# stdin から PreToolUse イベントの JSON を読み取る
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [ -z "$command" ]; then
  exit 0
fi

if ! echo "$command" | grep -qE 'git[^|;&]*[[:space:]]push([[:space:]]|$)'; then
  exit 0
fi

repo="${cwd:-.}"
if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

default_ref=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) ||
  default_ref="origin/main"
if ! git -C "$repo" rev-parse --verify --quiet "${default_ref}^{commit}" >/dev/null 2>&1; then
  exit 0
fi

commits=$(git -C "$repo" log --oneline "${default_ref}..HEAD" 2>/dev/null || true)
if [ -z "$commits" ]; then
  exit 0
fi

jq -n --arg ctx "Commits about to be pushed (${default_ref}..HEAD):
${commits}
Before pushing, verify every commit above belongs to the current task. Move unrelated commits to a separate branch instead of pushing them." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
