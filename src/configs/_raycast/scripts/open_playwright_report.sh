#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open playwright report
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🎭
# @raycast.packageName System

# Documentation:
# @raycast.description Open playwright report
# @raycast.author Nozomi Ishii
# @raycast.authorURL https://github.com/nozomiishii

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

# ----------------------------------------------------------------
# Constants
# ----------------------------------------------------------------
report_zip="$HOME/Desktop/playwright-report.zip"

# ----------------------------------------------------------------
# Node.js Version Manager
# ----------------------------------------------------------------
# This block is a placeholder for setting up the PATH to include
# your preferred Node.js version manager (e.g., Volta, nvm, asdf, n).
# Modify the code below to configure the PATH for the version
# manager you are using.

# Example for Volta:
if [ -d "$HOME/.volta" ]; then
  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"
fi
# Add your Node.js version manager configuration below:

# ----------------------------------------------------------------
# Functions
# ----------------------------------------------------------------
msg_error() {
  local message=$1
  local red="\033[1;31m"
  local reset='\033[0m'

  echo -e "${red}ERROR: ${message}${reset}"
}

main() {
  if ! command -v node &> /dev/null; then
    msg_error "node is not installed. Please install Node.js and npm to use this script. Additionally, ensure that the path to your Node.js version manager is correctly configured in the 'Node.js Version Manager' section of this script."
    exit 1
  fi

  if [ ! -f "$report_zip" ]; then
    msg_error "playwright-report.zip not found on Desktop."
    exit 1
  fi

  local report_directory
  report_directory="${report_zip%.zip}"

  unzip -o "$report_zip" -d "$report_directory"

  open "http://localhost:8080"
  npx http-server "$report_directory"
}
main
