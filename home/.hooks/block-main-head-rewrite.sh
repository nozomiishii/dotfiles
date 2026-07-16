#!/usr/bin/env bash
set -euo pipefail

# main の先端コミットへの amend / reset を検出・ブロックする PreToolUse Hook
#
# ブランチを切った直後は HEAD がリモート default branch の先端コミットのまま。
# この状態で commit-msg hook (commitlint) が失敗するとコミットは作られないが、
# 「直前のコミットを直す」つもりの `git commit --amend` や `git reset HEAD~1` が
# main のコミット自体を書き換え、その差分を自分の変更として巻き込む。
# 実際に PR へ無関係な変更が混入した:
# https://github.com/nozomiishii/dotfiles/pull/1327
# https://github.com/nozomiishii/dotfiles/pull/1328
#
# HEAD が default branch に含まれる = このブランチに自分のコミットは 1 つも無い。
# その状態での amend / commit-ish 指定の reset は常に誤操作なので決定論的に拒否する。
# 自分のコミットが 1 つでもあれば HEAD は default branch に含まれず、素通りする。

# stdin から PreToolUse イベントの JSON を読み取る
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

if [ -z "$command" ]; then
  exit 0
fi

# コマンド区切り (| ; &&) を跨がずに amend / commit-ish 指定の reset を検出する。
# reset は unstage 用法 (`git reset`, `git reset <path>`, `git reset HEAD <path>`) を
# 許可するため、HEAD~ / HEAD^ / SHA を対象にしたものだけを対象にする。
amend_pattern='git[^|;&]*[[:space:]]commit[^|;&]*--amend'
reset_pattern='git[^|;&]*[[:space:]]reset([[:space:]][^|;&]*)?[[:space:]](HEAD[~^]|[0-9a-f]{7,40}([[:space:]]|$))'

if ! echo "$command" | grep -qE "$amend_pattern|$reset_pattern"; then
  exit 0
fi

# 判定はツール実行時のカレントディレクトリ (hook 入力の cwd) の repo で行う
repo="${cwd:-.}"
if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# リモートの default branch を解決する。origin/HEAD 未設定の repo は origin/main に
# フォールバックし、それも無ければ (origin の無い repo 等) 判定せず素通りする。
default_ref=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) ||
  default_ref="origin/main"
if ! git -C "$repo" rev-parse --verify --quiet "${default_ref}^{commit}" >/dev/null 2>&1; then
  exit 0
fi

if git -C "$repo" merge-base --is-ancestor HEAD "$default_ref" 2>/dev/null; then
  head_sha=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo "HEAD")
  jq -n --arg reason "Blocked: HEAD ($head_sha) is a commit that already exists on $default_ref — this branch has no commits of its own yet. Amending or resetting here rewrites a $default_ref commit and sweeps its diff into your change (this caused unrelated changes in past PRs). If a commit-msg hook (commitlint) just failed, no commit was created: fix the message and run a plain \`git commit\` again." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
fi
