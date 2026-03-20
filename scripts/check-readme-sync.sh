#!/usr/bin/env bash
#
# check-readme-sync.sh - README.md と README.ja.md の同期チェック
#
# 変更されたファイル一覧を stdin で受け取り、README.md と README.ja.md の
# どちらか片方だけが変更されている場合にエラーで終了する。
#
# Usage:
#   git diff --cached --name-only | bash scripts/check-readme-sync.sh   # lefthook (pre-commit)
#   gh pr diff 123 --name-only | bash scripts/check-readme-sync.sh      # GitHub Actions (CI)
#
set -euo pipefail

changed=$(cat)
has_en=$(echo "$changed" | grep -cx 'README\.md' || true)
has_ja=$(echo "$changed" | grep -cx 'README\.ja\.md' || true)

if [ "$has_en" -ne "$has_ja" ]; then
  echo "ERROR: README.md and README.ja.md should be updated together."
  exit 1
fi

