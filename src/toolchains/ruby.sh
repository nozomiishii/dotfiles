#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
NO_COLOR='\033[0m'

echo -e '🐙 Ruby\n'

echo '- 🐙 Install rbenv'
brew install rbenv
eval "$(rbenv init -)"
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
