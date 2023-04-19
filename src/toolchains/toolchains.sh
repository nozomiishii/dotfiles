#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

toolchains_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# shellcheck source=../../utils/msg/msg.sh
source "$toolchains_dir/../../utils/msg/msg.sh"

msg --title "🌝 Initializing toolchains setup..."

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

msg --success "🌝 Toolchains setup is complete 🎉"
