#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# Print a message with specified type
#
# Usage:
#   msg [options] "message"
msg() {
  local red="\033[1;31m"
  local green="\033[0;32m"
  local yellow="\033[1;33m"
  local white="\033[1;37m"
  local bg_blue="\033[44m"
  local reset='\033[0m'

  local message
  local color
  local prefix
  local suffix
  local newline_before
  local newline_after

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --error)
        color="${red}"
        prefix="ERROR: "
        newline_after="\n\n"
        ;;
      --pass)
        color="${green}"
        prefix="✓${reset} "
        ;;
      --success)
        color="${green}"
        newline_before="\n\n"
        newline_after="\n\n"
        ;;
      --title)
        color="${bg_blue}${white}"
        newline_after="\n"
        ;;
      --warning)
        color="${yellow}"
        prefix="Warning: "
        ;;
      *)
        message="$1"
        ;;
    esac
    shift
  done

  echo -e "${newline_before}${color}${prefix}${message}${suffix}${reset}${newline_after}"
}