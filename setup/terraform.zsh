#!/usr/bin/env zsh
echo "\n🛰 Starting Terraform Setup\n"

if ! type terraform > /dev/null 2>&1; then
  GREP_OPTIONS="--color=never" tfenv install latest
  source ~/.zshrc 
  tfenv use $(echo $(tfenv list) | cut -d " " -f 1)
  terraform --version
fi 
