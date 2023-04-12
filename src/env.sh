#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

echo -e "🌝 Starting Environment setup...\n\n"

# ----------------------------------------------------------------
# Node
# ----------------------------------------------------------------
echo -e '🐉 Node\n'

echo '- 🐉 Install Node with Volta⚡️'
curl https://get.volta.sh | bash
echo "- ⚡️ volta $(volta --version)"

volta install node
volta install yarn@1

echo "- 🐉 node $(node --version)"
echo "- 🚚 yarn $(yarn --version)"

echo '- 🐉 Setup corepack'
yarn global add corepack
corepack enable
corepack enable npm

echo -e "\n${GREEN}🐉 Node setup is complete 🎉${NO_COLOR}\n\n"

# ----------------------------------------------------------------
# Rust
# ----------------------------------------------------------------
echo -e '🦀 Rust\n'
if ! command -v rustup > /dev/null 2>&1; then
  echo '- 🦀 Install Rust'
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

# ----------------------------------------------------------------
# Python
# ----------------------------------------------------------------
echo -e '🐍 Python\n'

echo '- 🐍 Install pyenv'
brew install pyenv
echo "- 🐍 $(pyenv --version)"

echo '- 🐍 Install Poetry'
curl -sSL https://install.python-poetry.org | python3 -
echo "- 🐍 $(poetry --version)"

echo -e "\n${GREEN}🐍 Python setup is complete 🎉${NO_COLOR}\n\n"

# ----------------------------------------------------------------
# Ruby
# ----------------------------------------------------------------
echo -e '🐙 Ruby\n'
# to format just only Brewfile🥹

echo '- 🐙 Install rbenv'
brew install rbenv
echo "- 🐙 $(rbenv --version)"

echo '- 🐙 Install ruby-build'
brew install ruby-build
echo "- 🐙 $(ruby-build --version)"

ruby_version=$(ruby -e 'puts RUBY_VERSION')
required_version="3.1.4"

if [ "$ruby_version" != "$required_version" ]; then
  echo '- 🐙 Install Ruby version'
  rbenv install "$required_version"
  rbenv global "$required_version"
fi
echo "- 🐙 $(ruby --version)"

echo '- 🐙 Setup gem'
gem install rufo

echo -e "\n${GREEN}🐙 Ruby setup is complete 🎉${NO_COLOR}\n\n"

# ----------------------------------------------------------------
# Result
# ----------------------------------------------------------------
echo -e "\n\n${GREEN}🎉 All Environment setup is complete 🎉${NO_COLOR}\n\n"
