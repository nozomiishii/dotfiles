#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo "- 🧮 duti"

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
