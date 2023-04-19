#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

configs_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../../utils/create_symlinks/create_symlinks.sh
source "$configs_dir/../../utils/create_symlinks/create_symlinks.sh"
# shellcheck source=../../utils/msg/msg.sh
source "$configs_dir/../../utils/msg/msg.sh"

msg --title "🧝🏻‍♀️ Starting Configs setup..."

create_symlinks --source "$configs_dir" --target "$HOME"

msg --success "🧝🏻‍♀️ Setup Configs is complete 🎉"
