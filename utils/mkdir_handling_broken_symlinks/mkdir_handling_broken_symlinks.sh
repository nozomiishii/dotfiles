#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

mkdir_handling_broken_symlinks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../msg/msg.sh
source "$mkdir_handling_broken_symlinks_dir/../msg/msg.sh"

# Create a directory, handling broken symlinks if necessary
# Usage: mkdir_handling_broken_symlinks "target_path"
mkdir_handling_broken_symlinks() {
  local target_path="$1"

  if ! mkdir -p "${target_path}"; then
    msg --warning "${target_path}"
    msg --warning "Failed to create directory, trying to remove broken symlink and recreate the directory"

    rm -f "${target_path}"

    mkdir -p "${target_path}" || {
      msg --warning "${target_path}"
      msg --warning "Failed to create directory after removing broken symlink"
      exit 1
    }
  fi
}
