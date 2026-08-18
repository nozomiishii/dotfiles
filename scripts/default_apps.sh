#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo "- 🧮 duti"

if [ "${CI:-false}" = "true" ]; then
  echo "Running in CI environment, exiting script."
  exit 0
fi

# Cursor.app: com.todesktop.230313mzl4w4u92
EDITOR_BUNDLE_ID="com.microsoft.VSCode"

editor_extensions=(
  toml
  yaml
  yml
  json
  jsonc
  css
  markdown
  sh
  js
  ts
  tsx
  svg
  pem
)

for ext in "${editor_extensions[@]}"; do
  duti -s "$EDITOR_BUNDLE_ID" "$ext" all
done
duti -s org.videolan.vlc mp4 all
