#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'
toolchains_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo -e "🌝 Starting Environment setup...\n\n"

# ----------------------------------------------------------------
# Node
# ----------------------------------------------------------------
source "$toolchains_dir/node.sh"

# ----------------------------------------------------------------
# Python
# ----------------------------------------------------------------
source "$toolchains_dir/python.sh"

# ----------------------------------------------------------------
# Ruby
#
# Just want to format just only Brewfile🥹
# ----------------------------------------------------------------
source "$toolchains_dir/ruby.sh"

# ----------------------------------------------------------------
# Rust
# ----------------------------------------------------------------
source "$toolchains_dir/rust.sh"

echo -e "\n\n${GREEN}🌝 All Environment setup is complete 🎉${RESET}\n\n"
