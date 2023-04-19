#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Ceu

run_all_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../get_target_files/get_target_files.sh
source "$run_all_dir/../get_target_files/get_target_files.sh"

# ----------------------------------------------------------------
# Function
# ----------------------------------------------------------------

# Run a specified tool against a set of target files while ignoring others.
#
# Usage:
#   run_all --tool "tool_command" --target "target_patterns" --ignore "ignore_patterns"
#
# Example:
#   run_all --tool "shfmt -w -i 2 -bn -ci -sr" --target "*.sh" --ignore "submodules/**"
#
run_all() {
  local GREEN='\033[0;32m'
  local BG_GREEN='\033[42m'
  local RED='\033[0;31m'
  local BG_RED='\033[41m'
  local WHITE='\033[1;37m'
  local RESET='\033[0m'

  local tool
  local target_patterns=()
  local ignore_patterns=()

  # ----------------------------------------------------------------
  # Opetions
  # ----------------------------------------------------------------
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --tool)
        shift
        tool="$1"
        ;;
      --target)
        shift
        IFS=' ' read -ra target_patterns <<< "$1"
        ;;
      --ignore)
        shift
        IFS=' ' read -ra ignore_patterns <<< "$1"
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done

  # ----------------------------------------------------------------
  # implementation
  # ----------------------------------------------------------------
  local exit_status=0
  local processed_files_count=0
  local failed_files_count=0
  local failed_files=""

  local target_files
  target_files=$(get_target_files --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}")

  for file in $target_files; do
    if eval "$tool" "\"$file\""; then
      processed_files_count=$((processed_files_count + 1))
      echo -e "${GREEN}✓${RESET} $file"
    else
      echo -e "${RED}✗${RESET} $file"
      exit_status=1
      failed_files_count=$((failed_files_count + 1))
      failed_files+="$file"$'\n'
    fi
  done

  # ----------------------------------------------------------------
  # Result
  # ----------------------------------------------------------------
  if [ "$exit_status" -eq 0 ]; then
    echo -e "\n\n${BG_GREEN}${WHITE}PASS${GREEN} Great job! All $processed_files_count files processed successfully.${RESET}\n\n"
  else
    echo -e "\n\n${BG_RED}${WHITE}FAIL${RED} Oops! Failed to process $failed_files_count files.${RESET}\n$failed_files\n\n"
  fi

  return "$exit_status"
}
