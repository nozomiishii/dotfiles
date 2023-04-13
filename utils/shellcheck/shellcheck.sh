#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Cu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# shellcheck disable=SC1091 source=../get_target_files/get_target_files.sh
source "$SCRIPT_DIR/../get_target_files/get_target_files.sh"

# Initialize a variable to track the exit status
exit_status=0
formatted_files_count=0
failed_files_count=0
failed_files=""

# List of directories and files to target (glob patterns)
target_patterns=(
  "*.sh"
  "*.bash"
  "*.bats"
  # "*.dash"
  # "*.ksh"
)

# List of directories and files to ignore (glob patterns)
ignore_patterns=(
  "submodules/**"
)

target_files=$(get_target_files --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}")

for file in $target_files; do

  # Define shellcheck options as an array
  # -e CODE1,CODE2..    --exclude=CODE1,CODE2..    Exclude types of warnings
  options=(--exclude=SC1091)

  if shellcheck "${options[@]}" "$file"; then
    formatted_files_count=$((formatted_files_count + 1))
    echo "Lint: $file"
  else
    exit_status=1
    failed_files_count=$((failed_files_count + 1))
    failed_files+="$file"$'\n'
  fi
done

GREEN='\033[0;32m'
RED='\033[0;31m'
NO_COLOR='\033[0m'

if [ "$exit_status" -eq 0 ]; then
  echo -e "\n\n${GREEN}Success: No ShellCheck warnings or errors for $formatted_files_count files.${NO_COLOR}\n\n"
else
  echo -e "\n\n${RED}Failure: ShellCheck warnings or errors found on $failed_files_count files:${NO_COLOR}\n$failed_files\n\n"
fi

exit "$exit_status"
