#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e '🦀 Rust\n'

# Officially recommended rustc installation path
recommended_rustc_path="$HOME/.cargo/bin/rustc"

# Check if rustc is installed and not in the recommended path
if command -v rustc &> /dev/null && [ "$(command -v rustc)" != "$recommended_rustc_path" ]; then
  echo "- 🦀 rustc is installed in a non-recommended path. Uninstalling it."

  # Check if rustc is installed via Homebrew
  if brew list rust &> /dev/null; then
    brew uninstall rust
    echo "- 🦀 rustc has been uninstalled using Homebrew."
  else
    echo "- 🦀 Could not determine how rustc was installed. Please uninstall manually."
  fi
fi

echo '- 🦀 Install Rust'

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck disable=SC1091
source "$HOME/.cargo/env"

rustup update
echo "- 🦀 $(rustup --version)"
echo "- 🦀 $(rustc --version)"
echo "- 🦀 $(rustdoc --version)"
echo "- 🦀 $(cargo --version)"

echo '- 🦀 Setup rust-analyzer'
rustup component add rust-analyzer
rustup toolchain install stable-aarch64-apple-darwin

echo '- 🦀 Setup Cargo global'
cargo install cargo-edit
cargo install cargo-watch
cargo install cargo-nextest
cargo install cargo-modules
cargo install cargo-make
cargo install create-tauri-app
cargo install wasm-pack
cargo install sea-orm-cli
# cargo install diesel_cli --no-default-features --features postgres

echo -e "\n${GREEN}🦀 Rust setup is complete 🎉${RESET}\n\n"
