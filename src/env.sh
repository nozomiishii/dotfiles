#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

printf "🌝 Starting Environment setup(asdf)... \n"

if [ ! -f ~/.tool-versions ]; then
  echo '⚠️ ~/.tool-versions is not exist'
  echo 'Run "./install -l" first'
  exit
fi

plugins=$(awk '{print $1}' ~/.tool-versions)
for plugin in $plugins; do
  if [ ! -d ~/.asdf/plugins/"$plugin" ]; then
    asdf plugin add "$plugin"
  fi
done

is_runtime_versions_changed() {
  plugin="$1"
  specified=$(grep "$plugin" ~/.tool-versions | awk '{$1=""; print $0}')
  installed=$(asdf list "$plugin" 2>&1)

  is_changed=
  for version in $specified; do
    match=$(echo "$installed" | grep "$version")
    [ -z "$match" ] && is_changed=1
  done
  [ "$is_changed" ]
}

for plugin in $(asdf plugin list); do
  if is_runtime_versions_changed "$plugin"; then
    echo "- 🚀 Installing plugin: $plugin"
    asdf install "$plugin"
  fi
done

# ----------------------------------------------------------------
# Node
# ----------------------------------------------------------------
echo -e '\n\n🐉 Node\n'
if ! command -v volta > /dev/null 2>&1; then
  echo '- 🐉 Install Node with Volta⚡️'
  curl https://get.volta.sh | bash
fi
echo "- ⚡️ volta $(volta --version)"

volta install node
volta install yarn@1

echo "- 🐉 node $(node --version)"
echo "- 🚚 yarn $(yarn --version)"

echo '- 🐉 Setup corepack'
if ! command -v corepack > /dev/null 2>&1; then
  yarn global add corepack
fi
corepack enable
corepack enable npm

# ----------------------------------------------------------------
# Rust
# ----------------------------------------------------------------
echo -e '\n\n🦀 Rust\n'
if ! command -v rustup > /dev/null 2>&1; then
  echo '- 🦀 Install Rust'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

echo "- 🦀 $(rustup --version)"
echo '- 🦀 Setup rust-analyzer'
rustup component add rust-analyzer
rustup toolchain install stable-aarch64-apple-darwin

echo "- 🦀 $(cargo --version)"
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

# ----------------------------------------------------------------
# Python
# ----------------------------------------------------------------
echo -e '\n\n🐍 Python\n'
if ! command -v poetry > /dev/null 2>&1; then
  echo '- 🐍 Install Poetry'
  curl -sSL https://install.python-poetry.org | python3 -
fi
echo "- 🐍 $(poetry --version)"

# ----------------------------------------------------------------
# Ruby
# ----------------------------------------------------------------
echo -e '\n\n🐙 Ruby\n'
# to format just only Brewfile🥹
ruby_version=$(ruby -e 'puts RUBY_VERSION')
required_version="3.1.4"
if [ "$ruby_version" != "$required_version" ]; then
  echo '- 🐙 Install Ruby'
  rbenv install "$required_version"
  rbenv global "$required_version"
fi
echo "- 🐙 $(ruby --version)"

echo '- 🐙 Setup Ruby'
gem install rufo

# ----------------------------------------------------------------
# Result
# ----------------------------------------------------------------
GREEN='\033[0;32m'
NO_COLOR='\033[0m'
echo -e "\n\n${GREEN}🎉 The Environment setup is complete${NO_COLOR}\n\n"
