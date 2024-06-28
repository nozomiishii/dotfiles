#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo "- 🤖 Automator"
if [ ! -f "$HOME/Desktop/OpenWithVisualStudioCode.workflow" ]; then
  cp -r "$HOME/.config/automator/OpenWithVisualStudioCode.workflow" "$HOME/Desktop"
fi
