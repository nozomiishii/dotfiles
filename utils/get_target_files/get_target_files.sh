#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Cu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# shellcheck disable=SC1091 source=../is_file_ignored/is_file_ignored.sh
source "$SCRIPT_DIR/../is_file_ignored/is_file_ignored.sh"

# Get the list of target files in the git repository, excluding deleted files
# and files matching the given exclude patterns.
# Usage: get_target_files "pattern1" "pattern2" ...
get_target_files() {
  local ignore_patterns=()
  local target_patterns=()

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --ignore)
        shift
        IFS=' ' read -ra ignore_patterns <<< "$1"
        ;;
      --target)
        shift
        IFS=' ' read -ra target_patterns <<< "$1"
        ;;
      *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
    shift
  done

  local tracked_files
  local deleted_files
  local untracked_files

  tracked_files=$(git ls-files)
  deleted_files=$(git ls-files --deleted)
  untracked_files=$(git ls-files --exclude-standard --others)

  # Remove deleted files from the tracked_files list
  for deleted_file in $deleted_files; do
    tracked_files=$(echo "$tracked_files" | grep -v "^$deleted_file$")
  done

  local target_files=""

  for file in $tracked_files $untracked_files; do
    if is_file_ignored "$file" "${ignore_patterns[@]}" || ! is_file_ignored "$file" "${target_patterns[@]}"; then
      continue
    fi

    target_files+="$file"$'\n'
  done

  echo "$target_files"
}
