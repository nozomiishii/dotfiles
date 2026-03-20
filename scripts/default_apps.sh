#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo "- 🧮 duti"

# duti -s com.microsoft.VSCode yaml all
# duti -s com.microsoft.VSCode json all
# duti -s com.microsoft.VSCode css all
# duti -s com.microsoft.VSCode markdown all
# duti -s com.microsoft.VSCode sh all
# duti -s com.microsoft.VSCode js all
# duti -s com.microsoft.VSCode ts all

# Cursor.app
# https://github.com/desktop/desktop/issues/17462
CURSOR_BUNDLE_ID="com.todesktop.230313mzl4w4u92"

cursor_extensions=(
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
)

for ext in "${cursor_extensions[@]}"; do
  duti -s "$CURSOR_BUNDLE_ID" "$ext" all
done
duti -s org.videolan.vlc mp4 all
