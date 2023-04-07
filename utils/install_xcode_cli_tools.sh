#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

# This function installs the Xcode Command Line Tools if they are not already installed.
#
# @See
# https://gist.github.com/mokagio/b974620ee8dcf5c0671f
# http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line
install_xcode_cli_tools() {
  # Check if Xcode CLI tools are already installed by trying to print the SDK path.
  if ! xcode-select -p &> /dev/null; then
    echo "👨🏻‍🚀 Xcode CLI tools not found. Installing them..."
    TEMP_FILE="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    touch "${TEMP_FILE}"

    CLI_TOOLS=$(softwareupdate -l \
      | grep "\*.*Command Line" \
      | tail -n 1 | sed 's/^[^C]* //')

    echo "👨🏻‍🚀 Installing: ${CLI_TOOLS}"
    softwareupdate -i "${CLI_TOOLS}" --verbose

    rm "${TEMP_FILE}"
  else
    echo "👨🏻‍🚀 Xcode CLI tools OK"
  fi
}
