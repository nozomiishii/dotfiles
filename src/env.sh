#!/bin/bash
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

if [ ! -d ~/.config/yarn/global/node_modules ]; then
  # corepackでyarnを管理する
  # https://shikiyura.com/2022/08/install_nodejs_using_asdf/
  corepack enable
  corepack enable npm
  corepack prepare yarn@1.22.19 --activate
  asdf reshim nodejs
  yarn -v

  echo '- 🚚 Setup Yarn global'
  # . $(brew --prefix asdf)/libexec/asdf.sh
  # export PATH="$(yarn global bin):$PATH"
  yarn global add

  # to use @prettier/ruby
  gem install bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs
fi

if type cargo > /dev/null 2>&1; then
  echo '- 🦀 Setup rust-analyzer'
  rustup component add rust-analyzer
  rustup toolchain install stable-aarch64-apple-darwin

  echo '- 📦 Setup Cargo global'
  cargo install cargo-edit
  cargo install cargo-watch
  cargo install cargo-nextest
  cargo install cargo-modules
  cargo install cargo-make
  cargo install wasm-pack
  cargo install diesel_cli --no-default-features --features postgres
  asdf reshim rust
fi

printf "🎉 The Environment setup is complete \n\n"
