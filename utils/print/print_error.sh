#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# Print a warning message in red color
# Usage: print_error "message"
print_error() {
  local message="$1"
  local red="\033[1;31m"
  local reset='\033[0m'

  echo -e "${red}ERROR: ${message}${reset}\n\n"
}
