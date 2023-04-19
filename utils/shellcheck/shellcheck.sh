#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Ceu

shellcheck_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../run_all/run_all.sh
source "$shellcheck_dir/../run_all/run_all.sh"

target_patterns=(
  "*.sh"
  "*.bash"
  "*.bats"
  # "*.dash"
  # "*.ksh"
)

ignore_patterns=(
  "submodules/**"
)

# --exclude=CODE1,CODE2..  Exclude types of warnings
run_all --tool "shellcheck --exclude=SC1091" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"
