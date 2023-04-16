#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo -e "🌝 Starting Environment setup...\n\n"

# ----------------------------------------------------------------
# Node
# ----------------------------------------------------------------
source "$SCRIPT_DIR/node.sh"

# ----------------------------------------------------------------
# Python
# ----------------------------------------------------------------
source "$SCRIPT_DIR/python.sh"

# ----------------------------------------------------------------
# Ruby
#
# Just want to format just only Brewfile🥹
# ----------------------------------------------------------------
source "$SCRIPT_DIR/ruby.sh"

# ----------------------------------------------------------------
# Rust
# ----------------------------------------------------------------
source "$SCRIPT_DIR/rust.sh"

echo -e "\n\n${GREEN}🌝 All Environment setup is complete 🎉${RESET}\n\n"
