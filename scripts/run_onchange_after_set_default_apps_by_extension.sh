#!/bin/bash

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
duti -s com.todesktop.230313mzl4w4u92 toml all
duti -s com.todesktop.230313mzl4w4u92 yaml all
duti -s com.todesktop.230313mzl4w4u92 yml all
duti -s com.todesktop.230313mzl4w4u92 json all
duti -s com.todesktop.230313mzl4w4u92 jsonc all
duti -s com.todesktop.230313mzl4w4u92 css all
duti -s com.todesktop.230313mzl4w4u92 markdown all
duti -s com.todesktop.230313mzl4w4u92 sh all
duti -s com.todesktop.230313mzl4w4u92 js all
duti -s com.todesktop.230313mzl4w4u92 ts all
duti -s com.todesktop.230313mzl4w4u92 tsx all
duti -s com.todesktop.230313mzl4w4u92 svg all
duti -s org.videolan.vlc mp4 all
