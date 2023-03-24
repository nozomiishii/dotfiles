#!/bin/bash
set -Ceu

printf "💻 Starting MacOS setup... \n"

echo "- 🤖 nvram"
# Disable auto-booting
sudo nvram AutoBoot=%01
# stop startup chime
sudo nvram StartupMute=%01
sudo nvram SystemAudioVolume=%80

echo "- 🔋 Battery"
# pmset – manipulate power management settings
# The settings are saved in /Library/Preferences/com.apple.PowerManagement.plist

# Do not dim brightness on battery source (-b: battery)
sudo pmset -b lessbright 0
# Prevent your mac from sleeping automatically when the display is off
sudo pmset -c sleep 0

echo "- 🚢 Dock" # killall Dock
# Set the Dock position
defaults write com.apple.dock orientation -string "right"
# Autohides the Dock. You can toggle the Dock using ⌥ + ⌘ +d.
defaults write com.apple.dock autohide -bool true
# Change the Dock opening delay.
defaults write com.apple.Dock autohide-delay -float 60
# Wipe all app icons
defaults write com.apple.dock persistent-apps -array
# Set the icon size of Dock items in pixels.
defaults write com.apple.dock tilesize -int 48
# Magnificate icons
defaults write com.apple.dock magnification -bool true
# Icon size of magnified Dock items
defaults write com.apple.dock largesize -int 56
# disable Launchpad
defaults write com.apple.dock showLaunchpadGestureEnabled -bool false

echo "- 🕹 Menu bar" # killall SystemUIServer
# This setting configures the time and date format for the menubar digital clock
defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM  h:mm a"
# Time format 12 hour time: AM/PM
defaults write NSGlobalDomain AppleICUForce12HourTime -bool true
# Configure the menu bar Items
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"
# Not Share Do Not Disturb status across devicess
defaults write com.apple.donotdisturbd disableCloudSync -bool true

echo "- 🪁 Control Center"
# Hide Spotlight
defaults write com.apple.controlcenter "NSStatusItem Visible Item-0" -bool false
# Hide Do Not Disturb
defaults write com.apple.controlcenter "NSStatusItem Visible DoNotDisturb" -bool false
# Hide Screen Mirroring
defaults write com.apple.controlcenter "NSStatusItem Visible ScreenMirroring" -bool false
# Hide Display
defaults write com.apple.controlcenter "NSStatusItem Visible Display" -bool false
# Hide Sound
defaults write com.apple.controlcenter "NSStatusItem Visible Sound" -bool false
# Hide Now Playing
defaults write com.apple.controlcenter "NSStatusItem Visible NowPlaying" -bool false

echo "- 📸 Screenshot"
# Choose whether to display a thumbnail after taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool false

echo "- 🐤 NSGlobalDomain(General)"
# Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
# Set double-click a window's title bar to None
defaults read NSGlobalDomain AppleActionOnDoubleClick -string "None"
# Set the accent color to green
defaults write NSGlobalDomain AppleAccentColor -int 3
# Set the highlight color to green
defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"
# Autohides the Menu bar
# defaults write NSGlobalDomain _HIHideMenuBar -bool true
# Show all file extensions in the Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Turn off alert volume
defaults write NSGlobalDomain com.apple.sound.beep.volume -int 0
# Use keyboard navigation to move focus between controls
# Press the Tab key to move focus forward and Shift Tab to move focus backward
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
# Turn off auto correct spelling
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false
# Turn off auto capitalize
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Turn off auto period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

echo "- 🗂 Finder" # killall Finder
# Set the default finder view style to icon view
defaults write com.apple.Finder FXPreferredViewStyle -string "icnv"
# Display the status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Display the path bar
defaults write com.apple.finder ShowPathbar -bool true
# Set a default folder when opening Finder: Google Drive
# Target category ex) PfDo: Documents, PfID: iCloud Drive, PfLo: Others
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/$USER"
# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

echo "- 🪧 Mission Control" # killall Dock
# Choose whether to rearrange Spaces automatically.
defaults write com.apple.dock mru-spaces -bool false

echo "- 👮🏻‍♂️ Security & Privacy"
# Turn on Firewall
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

echo "- ⌨️ Keyboard"
# Set key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
# Set delay until repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Fn key usage
defaults write com.apple.HIToolbox AppleFnUsageType -int 0
# Set automatically switch to a document's input source ON
# defaults write com.apple.HIToolbox AppleGlobalTextInputProperties -dict TextInputGlobalPropertyPerContextInput -int 1
#  @ = command
#  ^ = control
#  ~ = option
#  $ = shift
# General Keyboard Shortcut => Paste and Match Style : ⌘ + V => Use Command + Shift + V instead
# defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Paste and Match Style" -string "@v"
# Chrome Keyboard Shortcut => Browsing Data... : ⌃ + ⇧ + ⌘+ ⌥ + D
defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Clear Browsing Data..." -string "@~^\$d"
# Chrome Keyboard Shortcut => Print... : ⇧ + ⌘ + ⌥ + P
defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Print..." -string "@~\$p"
# Chrome Keyboard Shortcut => Save Page As... : ⇧ + ⌘ + ⌥ + S
defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Save Page As..." -string "@~\$s"
# Chrome Keyboard Shortcut => Bookmark This Tab... : ⇧ + ⌘ + ⌥ + D
defaults write com.google.Chrome NSUserKeyEquivalents -dict-add "Bookmark This Tab..." -string "@~\$d"
# Firefox Developer Edition Keyboard Shortcut => Save Page As... : ⇧ + ⌘ + ⌥ + P
defaults write org.mozilla.firefoxdeveloperedition NSUserKeyEquivalents -dict-add "Print..." -string "@~\$p"
# Disable ⌃ + Space for "Select the previous input source"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><false/></dict>'
# Disable ⌃ + ⌥ + Space for "Select next source in input menu"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '<dict><key>enabled</key><false/></dict>'
# Disable ⌘ + Space for "Show Spotlight search"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'
# Disable ⌥ + ⌘ + Space for "Show Finder search window"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '<dict><key>enabled</key><false/></dict>'
# Disable ⌃ + ↑ for "Mission Control"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 34 '<dict><key>enabled</key><false/></dict>'
# Disable ⌃ + ← for "Mission Control: Move left a space"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 '<dict><key>enabled</key><false/></dict>'
# Disable ⌃ + → for "Mission Control: Move right a space"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '<dict><key>enabled</key><false/></dict>'
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 '<dict><key>enabled</key><false/></dict>'

echo "- 📡 Network"
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8

echo "- 🖲 Trackpad"
# Haptic feedback => 0: Light 1: Medium 2: Firm
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0
# Tracking Speed => 0: Slow 3: Fast
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3
# Disable swipe between pages
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false
# Look up & data detectors
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad -int 2

echo "- 🗣 Speech"
# Enable Text to Speech
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyFlag -bool true
# Speak selected text when the key is pressed. Option + Space : 2097
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyCombo -int 2097

echo "- 🖥 Display"
# Nightshift https://github.com/smudge/nightlight
if ! type nightlight > /dev/null 2>&1; then
  brew install smudge/smudge/nightlight
fi
nightlight on
nightlight schedule 7:00 6:59

# Sidecar Settings
defaults write com.apple.sidecar.display doubleTapEnabled -bool true
defaults write com.apple.sidecar.display showTouchbar -bool false
defaults write com.apple.sidecar.display sidebarShown -bool false

# Delete Hot Corners
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 1048576

echo '- 📱 Simulator'
# Simulator lifetime 'When Simulator starts boot the most recently used simulator': off
defaults read com.apple.iphonesimulator StartLastDeviceOnLaunch -int 0

echo "- 👼 Killall..."
killall Dock
killall Finder
killall SystemUIServer
# cfprefsd helps an app or the system to read or write to preference files.
sudo killall cfprefsd
sudo killall corebrightnessd

printf "🎉 The MacOS setup is complete \n\n"
