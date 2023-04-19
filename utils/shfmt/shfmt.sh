#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Ceu

shfmt_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../run_all/run_all.sh
source "$shfmt_dir/../run_all/run_all.sh"

# List of directories and files to target (glob patterns)
target_patterns=(
  "*.sh"
  "*.bash"
  "*.bats"
  "*.dash"
  "*.ksh"
  "*.zsh"
)

# List of directories and files to ignore (glob patterns)
ignore_patterns=(
  "submodules/**"
  "**/p10k.zsh"
)

# -w,  --write     write result to file instead of stdout
# -i,  --indent uint       0 for tabs (default), >0 for number of spaces
# -bn, --binary-next-line  binary ops like && and | may start a line
# -ci, --case-indent       switch cases will be indented
# -sr, --space-redirects   redirect operators will be followed by a space
run_all --tool "shfmt -w -i 2 -bn -ci -sr" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"
