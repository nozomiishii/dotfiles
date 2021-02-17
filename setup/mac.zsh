#!/usr/bin/env zsh
echo "\n💻Starting Mac Setup\n"

# NOTE: Boolean | 0 = false, 1 = true


# Disable auto-booting
# sudo nvram AutoBoot=%01

# stop startup chime
# sudo nvram StartupMute=%01
# sudo nvram SystemAudioVolume=%80

echo "- 🚢 Dock \n" # killall Dock
# Set the Dock position
defaults write com.apple.dock orientation -string right
# Autohides the Dock. You can toggle the Dock using ⌥ + ⌘ +d.
defaults write com.apple.dock autohide -bool true
# Change the Dock opening delay.
defaults write com.apple.Dock autohide-delay -float 20
# Wipe all app icons
defaults write com.apple.dock persistent-apps -array
# Set the icon size of Dock items in pixels.
defaults write com.apple.dock tilesize -int 48 
# Magnificate icons
defaults write com.apple.dock magnification -bool true
# Icon size of magnified Dock items
defaults write com.apple.dock largesize -int 56


echo "- 🕹 Menu bar \n" # killall SystemUIServer
# This setting configures the time and date format for the menubar digital clock.
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  h:mm a"
# Autohides the Menu bar.
defaults write NSGlobalDomain _HIHideMenuBar -bool true
# Configure the menu bar Items
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"


echo "- 📸 Screenshot \n"
# Choose whether to display a thumbnail after taking a screenshot.
defaults write com.apple.screencapture show-thumbnail -bool false


echo "- 🗂 Finder \n" # killall Finder
# Set Accent color to green
defaults write NSGlobalDomain AppleAccentColor -int 3
# Set highlight color to green
defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"
# Show all file extensions in the Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true


echo "- 🖲 Mission Control \n" # killall Dock
# Choose whether to rearrange Spaces automatically.
defaults write com.apple.dock mru-spaces -bool false


echo "- ⌨️ Keyboard \n"
# Set key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
# Set delay until repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15


echo "- 👨🏻‍🚀 Restarting... \n"
killall Dock
killall Finder
killall SystemUIServer


echo "🎉 Completed Mac Setup \n"
