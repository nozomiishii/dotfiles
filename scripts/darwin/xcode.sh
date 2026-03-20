#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

# Installs the Xcode Command Line Tools if not already installed.
# @See
# https://gist.github.com/mokagio/b974620ee8dcf5c0671f
# http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line

echo -e "👨🏻‍🚀 Install Xcode CLI tools"
echo "- 👨🏻‍🚀 Checking Xcode CLI tools..."

if xcode-select -p &>/dev/null; then
  echo "- 👨🏻‍🚀 Xcode CLI tools are already installed"
else
  echo "- 👨🏻‍🚀 Xcode CLI tools not found. Installing them..."
  TEMP_FILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  touch "${TEMP_FILE}"

  CLI_TOOLS=$(softwareupdate -l |
    grep "\*.*Command Line" |
    tail -n 1 | sed 's/^[^C]* //')

  echo "- 👨🏻‍🚀 Installing: ${CLI_TOOLS}"
  softwareupdate -i "${CLI_TOOLS}" --verbose

  rm "${TEMP_FILE}"
fi

echo -e "👨🏻‍🚀 Xcode CLI tools are ready to go 🎉"
