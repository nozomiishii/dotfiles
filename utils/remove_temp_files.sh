#!/bin/bash
set -Ceu

# Removes temporary files specified as arguments.
# This function accepts a list of file paths and removes them if they exist.
#
# Usage:
# remove_temp_files <file_path_1> <file_path_2> ...
#
# Example:
# remove_temp_files "/tmp/temp_file_1" "/tmp/temp_file_2"
#
remove_temp_files() {
  for file_path in "$@"; do
    if [ -f "$file_path" ]; then
      rm "$file_path"
    fi
  done
}
