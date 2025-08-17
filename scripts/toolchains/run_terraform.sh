#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo '🛰️ Terraform'

# https://github.com/Schniz/fnm
echo '- 🛰️ Install Terraform with tenv🚀'

brew install tenv

tenv tf install latest-stable
# tenv tg install latest-stable

echo "- 🛰️ Terraform $(terraform -version)"
# echo "- 🛰️ tg $(tg --version)"

echo "🛰️ Terraform setup is complete 🎉"
