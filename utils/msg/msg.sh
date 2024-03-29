#!/bin/bash

# -C          : Prevent overwriting existing files when redirecting output.
#               - Helps to avoid accidentally overwriting files when using
#                 redirection operators like > or >> in the script.
# -e          : Exit the script if any command returns a non-zero status.
#               - Ensures the script stops on the first error encountered.
# -u          : Exit the script if an undefined variable is used.
#               - Prevents running commands with unintended variables.
# -o pipefail : Change pipeline exit status to the last non-zero exit code
#               in the pipeline, or zero if all commands succeed.
#               - Ensures proper error handling in pipelines.
# -x          : (Optional) Enable command tracing for easier debugging.
#               - Uncomment this option to debug the script.
set -Ceuo pipefail

# Print a message with specified type
#
# Usage:
#   msg [options] "message"
msg() {
  local blue='\033[0;34m'
  # local cyan='\033[36m'
  local red="\033[1;31m"
  local green="\033[0;32m"
  # local magenta="\033[35m"
  local yellow="\033[1;33m"
  local white="\033[1;37m"
  local bg_blue="\033[44m"
  local reset='\033[0m'

  local message=""
  local color="${white}"
  local prefix=""
  local suffix=""
  local newline_before=""
  local newline_after=""

  local is_stderr=0

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --check)
        color="${green}"
        prefix="✓${reset} "
        ;;
      --error)
        color="${red}"
        prefix="ERROR: "
        newline_after="\n\n"
        is_stderr=1
        ;;
      --info)
        color="${blue}"
        ;;
      --success)
        color="${green}"
        newline_before="\n\n"
        newline_after="\n\n"
        ;;
      --title)
        color="${bg_blue}${white}"
        prefix=" "
        suffix=" "
        newline_after="\n"
        ;;
      --warning)
        color="${yellow}"
        prefix="Warning: "
        is_stderr=1
        ;;
      *)
        message="$1"
        ;;
    esac
    shift
  done

  local message="${newline_before}${color}${prefix}${message}${suffix}${reset}${newline_after}"

  if [ "$is_stderr" -eq 1 ]; then
    echo -e "$message" >&2
    return
  fi
  echo -e "$message"
}
