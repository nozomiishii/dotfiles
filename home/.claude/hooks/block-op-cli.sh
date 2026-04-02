#!/usr/bin/env bash
set -euo pipefail

# 1Password CLI (op) の実行を検出・ブロックする PreToolUse Hook
#
# deny リストの "Bash(op:*)" は直接的な `op ...` コマンドをブロックするが、
# `bash -c "op item list"` や `sh -c "op ..."` のような間接実行は防げない。
# この Hook は Bash ツールに渡されるコマンド文字列全体をスキャンし、
# 間接パターンも含めて op CLI の実行を検出・拒否する。
#
# 背景: CVE-2025-55284 等の prompt injection 攻撃により、
# AI アシスタントが意図せず secrets 管理ツールを実行するリスクへの対策。

# stdin から PreToolUse イベントの JSON を読み取る
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# コマンド文字列内に op CLI の呼び出しパターンがあるか検出
# マッチ条件: 行頭・空白・セミコロン・&&・||・|・バッククォート・$( の直後に "op " が続く
if echo "$command" | grep -qE '(^|\s|;|&&|\|\|?|`|\$\()op\s'; then
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"1Password CLI (op) blocked by security hook (prompt injection protection)"}}'
  exit 0
fi
