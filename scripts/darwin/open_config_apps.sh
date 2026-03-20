#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

if [ "${CI:-false}" = "true" ]; then
  echo "Running in CI environment - skipping app opening"
  exit 0
fi

echo "👨🏻‍🚀 Open the apps that needs to be configured"
open -b com.apple.systempreferences
open "/Applications/Google Drive.app"
open "/Applications/Google Chrome.app"
open "/Applications/Raycast.app"
open "/Applications/1Password.app"
open /users
open https://github.com/nozomiishii/dotfiles
echo "👨🏻‍🚀 Please refer to github to set up the launched application"
