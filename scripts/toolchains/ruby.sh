#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🐙 Ruby'

echo '- 🐙 Install rbenv'
brew install rbenv
eval "$(rbenv init -)"
echo "- 🐙 $(rbenv --version)"

echo '- 🐙 Install ruby-build'
brew install ruby-build
echo "- 🐙 $(ruby-build --version)"

echo '- 🐙 Install openssl'
brew install openssl

echo '- 🐙 Install libyaml'
# https://qiita.com/notakaos/items/e3e30443b1e57f84e7d8
# https://zenn.dev/fuuukeee3/articles/22caeb537cf1a6
brew install libyaml

# Get the latest stable version of Ruby
# 1. List all installable Ruby versions with rbenv
# 2. Filter out non-stable versions (e.g., development, pre-release versions)
# 3. Get the last line, which is the latest stable version (rbenv list is sorted in ascending order)
# 4. Remove leading whitespace to get the version number only
latest_stable_version=$(rbenv install -l | grep -v - | tail -1 | sed 's/^ *//g')
ruby_version=$(ruby -e 'puts RUBY_VERSION')

if [ "$ruby_version" != "$latest_stable_version" ]; then
  echo '- 🐙 Install Ruby version'
  rbenv install "$latest_stable_version"
  rbenv global "$latest_stable_version"
fi
echo "- 🐙 $(ruby --version)"

echo '- 🐙 Setup gem'
gem install rufo

echo "🐙 Ruby setup is complete 🎉"
