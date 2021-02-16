#!/usr/bin/env zsh
echo "\n💻Starting Mac Setup\n"

# NOTE: Boolean | 0 = false, 1 = true 

echo "- 🚢 Dock \n"
# Set the Dock position
defaults write com.apple.dock orientation -string right
# Autohides the Dock. You can toggle the Dock using ⌥ + ⌘ +d.
defaults write com.apple.dock autohide -bool true
# Change the Dock opening delay.
defaults write com.apple.Dock autohide-delay -float 20
# Wipe all app icons
defaults write com.apple.dock persistent-apps -arrays
# Set the icon size of Dock items in pixels.
defaults write com.apple.dock tilesize -int 48 
# Magnificate icons
defaults write com.apple.dock magnification -bool true
# Icon size of magnified Dock items
defaults write com.apple.dock largesize -int 56


killall Dock
killall SystemUIServer
killall Finder
