#!/usr/bin/env zsh
echo "\n🛰 Starting Terraform Setup\n"

GREP_OPTIONS="--color=never" tfenv install latest
tfenv use $(echo $(tfenv list) | cut -d " " -f 1)
terraform --version
