#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

echo "🔌 Applying always-on power management settings..."

# Disable system sleep for all power sources
sudo pmset -a sleep 0

# Disable display sleep (useful for capture cards)
sudo pmset -a displaysleep 0

# Disable disk sleep
sudo pmset -a disksleep 0

# Enable Wake On Magic Packet (Wake On LAN)
sudo pmset -a womp 1

# Restart automatically after power loss
sudo pmset -a autorestart 1

# Keep TCP connections alive during sleep
sudo pmset -a tcpkeepalive 1

# Disable automatic logout (0 = disabled)
sudo defaults write /Library/Preferences/.GlobalPreferences \
  com.apple.autologout.AutoLogout \
  -int 0

# Disable password requirement after screensaver
defaults write com.apple.screensaver \
  askForPassword \
  -int 0

# Disable screensaver activation (idle time = 0)
defaults -currentHost write com.apple.screensaver \
  idleTime \
  -int 0

echo "📋 Current power settings:"
pmset -g
