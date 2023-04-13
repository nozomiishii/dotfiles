#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: Enable command tracing for easier debugging
set -Ceu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# shellcheck disable=SC1091 source=../run_all/run_all.sh
source "$SCRIPT_DIR/../run_all/run_all.sh"

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
