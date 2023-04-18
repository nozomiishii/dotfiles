#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# Print a warning message in yellow color
# Usage: print_warning "message"
print_warning() {
  local message="$1"
  local yellow='\033[1;33m'
  local reset='\033[0m'

  echo -e "${yellow}Warning: ${message}${reset}"
}
