#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

echo -e '🦀 Rust\n'

if ! command -v rustup > /dev/null 2>&1; then
  echo '- 🦀 Install Rust'
  export RUSTUP_INIT_SKIP_PATH_CHECK=yes
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi
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
cargo install diesel_cli --no-default-features --features postgres

echo -e "\n${GREEN}🦀 Rust setup is complete 🎉${NO_COLOR}\n\n"
