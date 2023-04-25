#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

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
