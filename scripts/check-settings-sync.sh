#!/usr/bin/env bash
#
# check-settings-sync.sh - home/.claude/settings.json と settings.md の同期チェック
#
# 変更されたファイル一覧を stdin で受け取り、settings.json と settings.md の
# どちらか片方だけが変更されている場合にエラーで終了する。
#
# settings.md に書かれた意味づけ（各 allow/deny の根拠など）が settings.json と
# 乖離するのを防ぐため。実際の同期作業は Claude Code の /sync-settings-doc で行う。
#
# Usage:
#   git diff --cached --name-only | bash scripts/check-settings-sync.sh   # lefthook (pre-commit)
#   gh pr diff 123 --name-only | bash scripts/check-settings-sync.sh      # GitHub Actions (CI)
#
set -euo pipefail

changed=$(cat)
has_json=$(echo "$changed" | grep -cx 'home/\.claude/settings\.json' || true)
has_md=$(echo "$changed" | grep -cx 'home/\.claude/settings\.md' || true)

if [ "$has_json" -ne "$has_md" ]; then
  echo "ERROR: home/.claude/settings.json と home/.claude/settings.md は同時に更新してください。"
  echo ""
  echo "Claude Code で /sync-settings-doc を実行して同期してから commit してください。"
  exit 1
fi
