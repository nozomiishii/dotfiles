#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# Print a warning message in green color
# Usage: print_pass "message"
print_pass() {
  local message="$1"
  local green='\033[0;32m'
  local reset='\033[0m'

  echo -e "${green}✓${reset} ${message}"
}
