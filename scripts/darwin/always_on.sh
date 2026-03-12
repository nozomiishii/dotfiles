#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# ----------------------------------------------------------------
# Always-on power settings (Mac mini, headless server, etc.)
#
# sleep 0     : Disable system sleep for all power sources (display off
#               does not trigger sleep).
# womp 1      : Enable Wake On Magic Packet (Wake On LAN).
# autorestart 1 : Restart automatically after power loss.
# ----------------------------------------------------------------
echo "🔌 Applying always-on power management settings..."

sudo pmset -a sleep 0
sudo pmset -a womp 1
sudo pmset -a autorestart 1

echo "📋 Current power settings:"
pmset -g
