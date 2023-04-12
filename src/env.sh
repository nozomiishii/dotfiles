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

if ! command -v poetry > /dev/null 2>&1; then
  echo '- 🐍 Install Poetry'
  curl -sSL https://install.python-poetry.org | python3 -

  poetry --version
fi

if ! command -v node > /dev/null 2>&1; then
  echo '- 🐉 Install Node with Volta⚡️'
  curl https://get.volta.sh | bash

  export VOLTA_HOME="$HOME/.volta"
  export PATH="$VOLTA_HOME/bin:$PATH"

  volta install node
  volta install yarn@1

  corepack enable
  corepack enable npm

  node -v
  yarn -v
fi

# to format just only Brewfile🥹
ruby_version=$(ruby -e 'puts RUBY_VERSION')
required_version="3.1.4"
if [ "$ruby_version" != "$required_version" ]; then
  rbenv install "$required_version"
  rbenv global "$required_version"

  eval "$(rbenv init - zsh)"
  gem install rufo
fi

if ! command -v cargo > /dev/null 2>&1; then
  echo '- 🦀 Install Rust'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  echo '- 🦀 Setup rust-analyzer'
  rustup component add rust-analyzer
  rustup toolchain install stable-aarch64-apple-darwin

  echo '- 📦 Setup Cargo global'
  cargo install cargo-edit
  cargo install cargo-watch
  cargo install cargo-nextest
  cargo install cargo-modules
  cargo install cargo-make
  cargo install create-tauri-app
  cargo install wasm-pack
  cargo install sea-orm-cli
  cargo install diesel_cli --no-default-features --features postgres
fi

printf "🎉 The Environment setup is complete \n\n"
