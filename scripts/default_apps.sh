#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
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

# VLC は Brewfile.optional のみのため、素の install.sh では未インストール。
# 未インストールの bundle id を duti に渡すと exit 2 で全体が止まる。
if [ -d "/Applications/VLC.app" ]; then
  duti -s org.videolan.vlc mp4 all
else
  echo "- 🧮 VLC not installed. Skipping mp4 handler"
fi
