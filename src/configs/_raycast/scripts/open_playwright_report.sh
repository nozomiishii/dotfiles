#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open playwright report
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🎭
# @raycast.packageName System

# Documentation:
# @raycast.description This script searches for Playwright report zip files in the Download path, allows the user to select one, extracts it, and opens the report in the default web browser. If only one report file is found, it will automatically open that report without prompting the user. Replace the DOWNLOAD_PATH variable with the path of your download and the REPORT_ZIP_PREFIX variable with the name of your report for the script to work properly.
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
DOWNLOAD_PATH="$HOME/Desktop"
REPORT_ZIP_PREFIX="playwright-report"

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

  echo -e "\n${red}ERROR: ${message}${reset}\n\n" >&2
}

select_report_zip() {
  local cyan=$'\e[36m'
  local reset=$'\e[0m'

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
  # | awk '{print $2}' : Extract the filename (second field) from the first line
  local report_files
  report_files=$(find "$DOWNLOAD_PATH" -maxdepth 1 -name "${REPORT_ZIP_PREFIX}*.zip" -type f -exec stat -f "%m %N" {} \; | sort -nr | awk '{print $2}')

  if [ -z "$report_files" ]; then
    msg_error "No ${REPORT_ZIP_PREFIX} file found on ${DOWNLOAD_PATH}"
    exit 1
  fi

  local -a options
  IFS=$'\n' read -rd '' -a options <<< "$report_files"

  if [ "${#options[@]}" -eq 1 ]; then
    echo "${options[0]}"
    return
  fi

  local selected_file
  PS3="${cyan}Choose the playwright-report zip file you want to open:${reset} "
  select opt in "${options[@]}"; do
    if [[ " ${options[*]} " == *" $opt "* ]]; then
      selected_file="$opt"
      break
    fi
  done

  echo "$selected_file"
}

main() {
  if ! command -v node &> /dev/null; then
    msg_error "node is not installed. Please install Node.js and npm to use this script. Additionally, ensure that the path to your Node.js version manager is correctly configured in the 'Node.js Version Manager' section of this script."
    exit 1
  fi

  # ----------------------------------------------------------------
  # Find Latest Report and Extract
  # ----------------------------------------------------------------
  local report_zip
  report_zip=$(select_report_zip)

  local report_directory="${report_zip%.zip}"
  unzip -o "$report_zip" -d "$report_directory"

  # ----------------------------------------------------------------
  # Launch HTTP Server and Open Report
  # ----------------------------------------------------------------
  local output_file
  output_file=$(mktemp)

  # http-server
  # https://www.npmjs.com/package/http-server
  #
  # --port 0  : Use --port 0 to look for an open port, starting at 8080.
  npx -y http-server --port 0 "$report_directory" 2>&1 | tee "$output_file" &
  # Get the PID of the server process
  server_pid=$!
  # Wait for the http-server output to be available
  sleep 2

  # Extract the port number from the output file
  # awk
  # -F:         : Use colon (:) as the field separator
  # {print $NF} : Print the last field (port number) of each record
  #
  # Remove escape sequences (color codes, styles, etc.) from the output.
  # sed $'s/\x1B\\[[0-9;]*[a-zA-Z]//g'
  local assigned_port
  assigned_port=$(grep -m1 -o -E "http:\/\/127\.0\.0\.1:([0-9]+)" "$output_file" | awk -F: '{print $NF}' | sed $'s/\x1B\\[[0-9;]*[a-zA-Z]//g')
  rm -f "$output_file"

  if [ -z "$assigned_port" ]; then
    msg_error "No assigned port found"
    exit 1
  fi

  open "http://localhost:${assigned_port}"
  # Bring the server process to the foreground and wait for it to finish
  wait $server_pid
}
main
