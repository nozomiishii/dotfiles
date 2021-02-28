#!/usr/bin/env zsh
echo "\n💻 Starting Mac Setup\n"
# sudo -v

echo "- 🔋 nvram"
# Disable auto-booting
sudo nvram AutoBoot=%01
# stop startup chime
sudo nvram StartupMute=%01
sudo nvram SystemAudioVolume=%80


echo "- 🚢 Dock" # killall Dock
# Set the Dock position
defaults write com.apple.dock orientation -string "right"
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


echo "- 🕹 Menu bar" # killall SystemUIServer
# This setting configures the time and date format for the menubar digital clock.
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  h:mm a"
# Autohides the Menu bar.
defaults write NSGlobalDomain _HIHideMenuBar -bool true
# Configure the menu bar Items
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"


echo "- 📸 Screenshot"
# Choose whether to display a thumbnail after taking a screenshot.
defaults write com.apple.screencapture show-thumbnail -bool false


echo "- 👼 General"
# Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Set the accent color to green
defaults write NSGlobalDomain AppleAccentColor -int 3
# Set the highlight color to green
defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"


echo "- 🗂 Finder" # killall Finder
# Show all file extensions in the Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Set the default finder view style to icon view
defaults write com.apple.Finder FXPreferredViewStyle -string "icnv"
# Display the status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Display the path bar
defaults write com.apple.finder ShowPathbar -bool true

echo "- 🖲 Mission Control" # killall Dock
# Choose whether to rearrange Spaces automatically.
defaults write com.apple.dock mru-spaces -bool false


echo "- ⌨️ Keyboard"
# Set key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
# Set delay until repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15


echo "- 📡 Network"
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8


echo "- 🗣 Speach"
# Enable Text to Speech
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyFlag -bool true
# Speak selected text when the key is pressed. Option + Space : 2097
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyCombo -int 2097
# System Voice
# System Voice > Customize… > English (United Kingdom): siri: on
defaults write com.apple.speech.voice.prefs VisibleIdentifiers -dict-add 'com.apple.speech.synthesis.voice.custom.siri.martha.premium' 1
defaults write com.apple.speech.voice.prefs SelectedVoiceCreator -int 1650811243
defaults write com.apple.speech.voice.prefs SelectedVoiceID -int 2100
defaults write com.apple.speech.voice.prefs SelectedVoiceName -string "Martha Siri"


echo "- 👨🏻‍🚀 Restarting..."
killall Dock
killall Finder
killall SystemUIServer

echo "\n🎉 Completed Mac Setup \n"


echo "\n🧝🏻‍♀️ Starting Third-Party Software Setup\n"


echo "- 🍎 Xcode"
XCODE_USERDATA="$HOME/Library/Developer/Xcode/UserData"
GOOGLE_DRIVE_XCODE_USERDATA="$HOME/Google Drive/settings/dotfiles/link/Xcode/UserData"
xcode_userdata=( "CodeSnippets" "FontAndColorThemes" "KeyBindings" )

for i in "${xcode_userdata[@]}"
do
  ln -nfs "$GOOGLE_DRIVE_XCODE_USERDATA/$i" "$XCODE_USERDATA/$i"
  if [ -L "$XCODE_USERDATA/$i" ]; then
    echo "Creating Link $XCODE_USERDATA/$i -> $GOOGLE_DRIVE_XCODE_USERDATA/$i"
  else
    echo "Error: Creating Links fails"
  fi
done


echo "- 🎮 iTerm2"
# iTerm2 Settings
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/Google Drive/settings/dotfiles/sync/iTerm2"
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


echo "- ⌨ Karabiner-Elements"
ln -nfs "$HOME/Google Drive/settings/dotfiles/sync/Karabiner-Elements/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

echo "\n🎉 Completed Third-Party Software Setup\n"
