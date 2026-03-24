#!/usr/bin/env bash
set -euo pipefail

LOCAL_SETTINGS="$CLAUDE_PROJECT_DIR/.claude/settings.local.json"

if [ ! -f "$LOCAL_SETTINGS" ]; then
  exit 0
fi

allow_count=$(jq '.permissions.allow // [] | length' "$LOCAL_SETTINGS" 2>/dev/null || echo 0)
deny_count=$(jq '.permissions.deny // [] | length' "$LOCAL_SETTINGS" 2>/dev/null || echo 0)
total=$((allow_count + deny_count))

if [ "$total" -gt 0 ]; then
  echo "⚠️ settings.local.json に ${total} 件のルールがあります（allow: ${allow_count}, deny: ${deny_count}）"
  echo "グローバル設定（~/.claude/settings.json）に移行してください。"
  echo ""
  jq '.permissions' "$LOCAL_SETTINGS" 2>/dev/null
fi
