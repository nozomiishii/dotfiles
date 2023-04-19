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
  local message
  local color
  local prefix
  local suffix

  local red="\033[1;31m"
  local green="\033[0;32m"
  local yellow="\033[1;33m"
  local reset='\033[0m'

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --error)
        color="$red"
        prefix="ERROR: "
        suffix="\n\n"
        ;;
      --pass)
        prefix="✓${reset} "
        color="$green"
        ;;
      --warning)
        prefix="Warning: "
        color="$yellow"
        ;;
      *)
        message="$1"
        ;;
    esac
    shift
  done

  echo -e "${color}${prefix}${message}${suffix}${reset}"
}
