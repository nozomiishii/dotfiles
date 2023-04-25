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
set -Ceu

# ----------------------------------------------------------------
# Constants
# ----------------------------------------------------------------
download_path="$HOME/Desktop"
report_zip_prefix="playwright-report"

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
#
# -----------------------------------------------
# START OF YOUR NODE JS VERSION MANAGER CONFIGURATION
#
# Please add your Node.js version manager configuration here.
# Refer to your version manager's documentation for the correct
# configuration settings.
#
# -----------------------------------------------
# END OF YOUR NODE JS VERSION MANAGER CONFIGURATION
#

# ----------------------------------------------------------------
# Functions
# ----------------------------------------------------------------
msg_error() {
  local message=$1
  local red="\033[1;31m"
  local reset='\033[0m'

  echo -e "${red}ERROR: ${message}${reset}" >&2
}

main() {
  if ! command -v node &> /dev/null; then
    msg_error "node is not installed. Please install Node.js and npm to use this script. Additionally, ensure that the path to your Node.js version manager is correctly configured in the 'Node.js Version Manager' section of this script."
    exit 1
  fi

  # ----------------------------------------------------------------
  # Find Latest Report and Extract
  # ----------------------------------------------------------------
  # Find all files in the download directory
  # -maxdepth 1 : Search only in the download directory, not in subdirectories
  # -name       : Match filenames with the specified pattern
  # -type f     : Search for files only, not directories
  # -exec       : Execute the 'stat' command on each matched file
  #
  # Use 'stat' to get the modification timestamp and filename for each file
  # -f "%m %N"  : Format the output with the modification timestamp (%m) and filename (%N)
  #
  # | sort -nr   : Sort the output numerically (-n) and in reverse order (-r)
  # | head -n 1  : Get the first line of the sorted output (the latest file)
  # | awk '{print $2}' : Extract the filename (second field) from the first line
  local latest_report_zip
  latest_report_zip=$(find "$download_path" -maxdepth 1 -name "${report_zip_prefix}*.zip" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -n 1 | awk '{print $2}')

  if [ -z "$latest_report_zip" ]; then
    msg_error "No ${report_zip_prefix} file with timestamp found on ${download_path}"
    exit 1
  fi

  local report_directory="${latest_report_zip%.zip}"
  unzip -o "$latest_report_zip" -d "$report_directory"

  # ----------------------------------------------------------------
  # Launch HTTP Server and Open Report
  # ----------------------------------------------------------------
  local output_file
  output_file=$(mktemp)

  # http-server
  # https://www.npmjs.com/package/http-server
  #
  # --port 0  : Use --port 0 to look for an open port, starting at 8080.
  npx http-server --port 0 "$report_directory" 2>&1 | tee "$output_file" &
  # Wait for the http-server output to be available
  sleep 2

  # Extract the port number from the output file
  local assigned_port
  assigned_port=$(grep -m1 -o -E "http:\/\/127\.0\.0\.1:([0-9]+)" "$output_file" | awk -F: '{print $NF}')

  if [ -z "$assigned_port" ]; then
    msg_error "No assigned port found"
    rm -f "$output_file"
    exit 1
  fi

  open "http://localhost:${assigned_port}"
  rm -f "$output_file"
}
main
