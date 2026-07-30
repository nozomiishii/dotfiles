#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🛰️ Terraform'

# https://tofuutils.github.io/tenv/
echo '- 🛰️ Install Terraform with tenv🚀'

brew install tenv

tenv tf install latest-stable
tenv tg install latest-stable

echo "- 🛰️ Terraform $(terraform -version)"

# terraform -install-autocomplete は使わない。~/.zshrc へ追記する方式で、symlink 先の
# repo が dirty になり git pull --rebase と make link が止まる。補完自体も OpenTofu へ
# 移行済みのため入れない

echo "🛰️ Terraform setup is complete 🎉"
