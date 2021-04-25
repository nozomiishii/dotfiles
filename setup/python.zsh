#!/usr/bin/env zsh
echo "\n🐍 Starting Python Setup\n"

python_version = 3.9.4

pyenv install $python_version
pyenv global $python_version

source ~/.zshrc 

echo "🐍 pyenv version"
pyenv versions

echo "🐍 python version"
python -V
