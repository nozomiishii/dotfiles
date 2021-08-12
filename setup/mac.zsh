#!/usr/bin/env zsh
echo "\n💻 Starting Mac Setup\n"


echo "- 🤖 nvram"
# Disable auto-booting
sudo nvram AutoBoot=%01
# stop startup chime
sudo nvram StartupMute=%01
sudo nvram SystemAudioVolume=%80


echo "- 🔋 Battery"
# Do not dim brightness on battery source (-b: battery)
sudo pmset -b lessbright 0


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


echo "- 📸 Screenshot"
# Choose whether to display a thumbnail after taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool false


echo "- 🐤 NSGlobalDomain(General)"
# Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
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
defaults write com.apple.finder NewWindowTargetPath -string "file:///Users/$USER/Google%20Drive/"
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
#  @ = command
#  ^ = control
#  ~ = option
#  $ = shift
# General Keyboard Shortcut => Paste and Match Style : ⌘ + V
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Paste and Match Style" -string "@v"
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


echo "- 📡 Network"
networksetup -setdnsservers Wi-Fi 2001:4860:4860::8844 2001:4860:4860::8888 8.8.4.4 8.8.8.8


echo "- 🖲 Trackpad"
# Haptic feedback => 0: Light 1: Medium 2: Firm
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0
# Tracking Speed => 0: Slow 3: Fast
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5
# Disable swipe between pages
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false
# Disable Look up & detectors
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0


echo "- 🗣 Speech"
# Enable Text to Speech
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyFlag -bool true
# Speak selected text when the key is pressed. Option + Space : 2097
defaults write com.apple.speech.synthesis.general.prefs SpokenUIUseSpeakingHotKeyCombo -int 2097


echo "- 🖥 Display"
# System Preference > Displays > Night Shift
# Night shift from 7am to 6:59am
CORE_BRIGHTNESS="/private/var/root/Library/Preferences/com.apple.CoreBrightness.plist"
CURRENT_USER_UID="CBUser-$(dscl . -read ~ GeneratedUID | sed 's/GeneratedUID: //')"

# Color Temperature: Default warm
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueLightReductionCCTTargetRaw 4100" $CORE_BRIGHTNESS
# Manual: Turn on Until Tomorrow => 4: check, 3: uncheck
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueLightReductionAlgoOverride 4" $CORE_BRIGHTNESS
# Schedule: Custom
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueReductionMode 2" $CORE_BRIGHTNESS
# From: Hour
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueLightReductionSchedule:NightStartHour 7" $CORE_BRIGHTNESS
# From: Minutes
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueLightReductionSchedule:NightStartMinute 0" $CORE_BRIGHTNESS
# To: Hour
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueLightReductionSchedule:DayStartHour 6" $CORE_BRIGHTNESS 
# To: Minutes
sudo /usr/libexec/PlistBuddy -c "Set :$CURRENT_USER_UID:CBBlueReductionStatus:BlueLightReductionSchedule:DayStartMinute 59" $CORE_BRIGHTNESS

# Sidecar Settings
defaults write com.apple.sidecar.display doubleTapEnabled -bool true
defaults write com.apple.sidecar.display showTouchbar -bool false
defaults write com.apple.sidecar.display sidebarShown -bool false


echo "- 👼 Killall..."
killall Dock
killall Finder
killall SystemUIServer
# cfprefsd helps an app or the system to read or write to preference files.
sudo killall cfprefsd
sudo killall corebrightnessd

echo "\n🎉 Completed Mac Setup \n"


echo "\n🧝🏻‍♀️ Starting Third-Party Software Setup\n"
APP_PREFERENCES="$HOME/dotfiles/apps"

echo "- 🐟 VSCode"
VSCODE_USERDATA="$HOME/Library/Application Support/Code/User"
CUSTOMIZED_VSCODE_USERDATA="$APP_PREFERENCES/VSCode"

VSCODE_USERDATA_ITEMS=("keybindings.json" "settings.json" "snippets")
for item in ${VSCODE_USERDATA_ITEMS[@]}; do
  rm -rf "$VSCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_VSCODE_USERDATA/$item" "$VSCODE_USERDATA/$item"
  if [ -L "$VSCODE_USERDATA/$item" ]; then
    echo "Created Link: $VSCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$VSCODE_USERDATA"


echo "- 🍎 Xcode"
XCODE_USERDATA="$HOME/Library/Developer/Xcode/UserData"
CUSTOMIZED_XCODE_USERDATA="$APP_PREFERENCES/Xcode/UserData"

XCODE_USERDATA_ITEMS=("CodeSnippets" "FontAndColorThemes" "KeyBindings")
for item in ${XCODE_USERDATA_ITEMS[@]}; do
  # Need rm -rf to symbolic-link KeyBindings folder
  rm -rf "$XCODE_USERDATA/$item"
  ln -nfsv "$CUSTOMIZED_XCODE_USERDATA/$item" "$XCODE_USERDATA/$item"
  if [ -L "$XCODE_USERDATA/$item" ]; then
    echo "Created Link: $XCODE_USERDATA/$item"
  else
    echo "Error: Creating Links fails"
  fi
done
ls -l "$XCODE_USERDATA"


echo "- 🧠 JetBrains (PyCharm)"
PYCHARM_USERDATA="$HOME/Library/Application Support/JetBrains"
CUSTOMIZED_PYCHARM_USERDATA="$APP_PREFERENCES/JetBrains"

rm -rf "$PYCHARM_USERDATA"
ln -nfsv "$CUSTOMIZED_PYCHARM_USERDATA" "$PYCHARM_USERDATA"
ls -l "$PYCHARM_USERDATA"



echo "- 🎮 iTerm2"
# General > Preferences > check "Load preferences from a custom folder or URL"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Restore from the backup
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$APP_PREFERENCES/iTerm2"
# General > Preferences > Save changes: when quits 
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true


echo "- ⛓ Karabiner-Elements"
rm -rf "$HOME/.config/karabiner"
ln -nfsv "$APP_PREFERENCES/karabiner" "$HOME/.config/karabiner"
# check if it works
ls -l "$HOME/.config" | grep karabiner


echo "- 🧲 Tiles"
# Don't show the icon in the menu bar
defaults write com.sempliva.Tiles.plist MenuBarIconEnabled -bool false
# Active Hotkeys
# Previous Display: ⌥ + ⌘ + A 
defaults write com.sempliva.Tiles.plist PreviousDisplay -dict-add "characters" -string "\U00e5"
defaults write com.sempliva.Tiles.plist PreviousDisplay -dict-add "charactersIgnoringModifiers" -string "a"
defaults write com.sempliva.Tiles.plist PreviousDisplay -dict-add "keyCode" -int 0
defaults write com.sempliva.Tiles.plist PreviousDisplay -dict-add "modifierFlags" -int 1572864
# Inactive Hotkeys
TILES_INACTIVE_HOTKEYS=("MoveToCenter" "NextThird" "PreviousThird" "FirstTwoThirds" "LastTwoThirds" "NextDisplay" "MoveToLowerLeft" "MoveToLowerRight" "MoveToUpperLeft" "MoveToUpperRight" "UndoLastMove")
for item in ${TILES_INACTIVE_HOTKEYS[@]}; do
  defaults write com.sempliva.Tiles.plist $item -dict-add "keyCode" -int 65535
  defaults write com.sempliva.Tiles.plist $item -dict-add "modifierFlags" -int 0
done


echo "- 🐵 Blender"
BLENDER_USERDATA="$HOME/Library/Application Support/Blender"
CUSTOMIZED_BLENDER_USERDATA="$APP_PREFERENCES/Blender"

rm -rf "$BLENDER_USERDATA"
ln -nfsv "$CUSTOMIZED_BLENDER_USERDATA" "$BLENDER_USERDATA"
ls -l "$BLENDER_USERDATA"



echo "- 🔖 Dash"
defaults write com.kapeli.dashdoc syncFolderPath "$APP_PREFERENCES/Dash"
defaults write com.kapeli.dashdoc snippetSQLPath "$APP_PREFERENCES/Dash/Snippets.dash"


echo "\n🎉 Completed Third-Party Software Setup\n"

echo "- 👼 Killall..."
killall Dock
killall Finder
killall SystemUIServer
sudo killall cfprefsd
sudo killall corebrightnessd

