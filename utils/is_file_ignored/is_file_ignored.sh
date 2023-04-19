#!/bin/bash

# is_file_ignored checks if a given file should be ignored based on a list of patterns.
# The function returns 0 (true) if the file matches any of the patterns, and 1 (false) otherwise.
#
# A pattern starting with a "!" (exclamation mark) will negate the match, meaning that if a file
# matches that pattern, it will not be ignored even if it matches other patterns.
#
# Usage:
#   is_file_ignored "file" "pattern1" "pattern2" "pattern3"
#
# Example:
#   is_file_ignored "test.txt" "*.txt" "!test.txt"  # returns 1 (false, file is not ignored)
#   is_file_ignored "test.txt" "*.txt"             # returns 0 (true, file is ignored)
#
is_file_ignored() {
  local file="$1"
  shift
  local patterns=("$@")
  local matched=1

  for pattern in "${patterns[@]}"; do
    if [[ $pattern == !* && $file == "${pattern#!}" ]]; then
      matched=1
      break
    fi

    # shellcheck disable=SC2053
    if [[ $file == $pattern ]]; then
      matched=0
    fi
  done

  return "$matched"
}
