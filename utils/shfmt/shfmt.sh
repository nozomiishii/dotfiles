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
  "*.zsh"
  "*.ksh"
  "*.dash"
  "*.bat"
  "*.cmd"
)

# List of directories and files to ignore (glob patterns)
ignore_patterns=(
  "submodules/**"
  "**/p10k.zsh"
)

target_files=$(get_target_files --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}")

for file in $target_files; do

  # Define shfmt options as an array
  # -w,  --write     write result to file instead of stdout
  # -i,  --indent uint       0 for tabs (default), >0 for number of spaces
  # -bn, --binary-next-line  binary ops like && and | may start a line
  # -ci, --case-indent       switch cases will be indented
  # -sr, --space-redirects   redirect operators will be followed by a space
  shfmt_options=(-w -i 2 -bn -ci -sr)

  if shfmt "${shfmt_options[@]}" "$file"; then
    formatted_files_count=$((formatted_files_count + 1))
    echo "Format: $file"
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
  echo -e "\n\n${GREEN}Success: $formatted_files_count files formatted correctly.${NO_COLOR}\n\n"
else
  echo -e "\n\n${RED}Failure: $failed_files_count files could not be formatted:${NO_COLOR}\n$failed_files\n\n"
fi

exit "$exit_status"
