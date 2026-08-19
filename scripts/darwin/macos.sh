#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

# ----------------------------------------------------------------
# macOS setup
# ----------------------------------------------------------------
echo "💻 Initializing MacOS setup..."

# ----------------------------------------------------------------
# nvram
# ----------------------------------------------------------------
echo "- 🤖 nvram"

# Disable auto-booting
sudo nvram AutoBoot=%01

# stop startup chime
sudo nvram StartupMute=%01
sudo nvram SystemAudioVolume=%80

# ----------------------------------------------------------------
# Battery
# ----------------------------------------------------------------
echo "- 🔋 Battery"
# pmset – manipulate power management settings
# The settings are saved in /Library/Preferences/com.apple.PowerManagement.plist

# Do not dim brightness on battery source (-b: battery)
sudo pmset -b lessbright 0

# Prevent your mac from sleeping automatically when the display is off
sudo pmset -c sleep 0

# Keep TCP connections alive during display sleep
# Required for SSH/Claude Code access while screen is locked
sudo pmset -c tcpkeepalive 1

# ----------------------------------------------------------------
# Dock
# ----------------------------------------------------------------
echo "- 🚢 Dock" # killall Dock

# Set the Dock position
defaults write com.apple.dock orientation -string "right"

# Autohides the Dock. You can toggle the Dock using ⌥ + ⌘ +d.
defaults write com.apple.dock autohide -bool true

# Change the Dock opening delay.
defaults write com.apple.Dock autohide-delay -float 60

# Wipe all app icons
defaults write com.apple.dock persistent-apps -array

# Hide recent apps
defaults write com.apple.dock show-recents -bool false

# Set the icon size of Dock items in pixels.
defaults write com.apple.dock tilesize -int 48

# Magnificate icons
defaults write com.apple.dock magnification -bool true

# Icon size of magnified Dock items
defaults write com.apple.dock largesize -int 56

# Stage Managerの運用やってみて合わなかったら消す
# disable Launchpad
# defaults write com.apple.dock showLaunchpadGestureEnabled -bool false

# disable Stage Manager
# defaults write com.apple.WindowManager GloballyEnabled -bool false

# disable Click wallpaper to reveal desktop
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# ----------------------------------------------------------------
# Menu bar
# ----------------------------------------------------------------
echo "- 🕹 Menu bar" # killall SystemUIServer

# Menu bar clock: 曜日 + AM/PM を表示、日付はスペースに余裕がある時だけ
# (旧 DateFormat キーは現行 macOS では読まれない)
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0

# Time format 12 hour time: AM/PM
defaults write NSGlobalDomain AppleICUForce12HourTime -bool true

# Show Time Machine in the menu bar
# (System Settings > Control Center の Show in Menu Bar トグルが書くキー。
#  旧 menuExtras 配列は現行 macOS では読まれない)
defaults write com.apple.systemuiserver "NSStatusItem VisibleCC com.apple.menuextra.TimeMachine" -bool true

# Not Share Do Not Disturb status across devicess
defaults write com.apple.donotdisturbd disableCloudSync -bool true

# ----------------------------------------------------------------
# Control Center
# ----------------------------------------------------------------
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

# ----------------------------------------------------------------
# Screenshot
# ----------------------------------------------------------------
echo "- 📸 Screenshot"

# Choose whether to display a thumbnail after taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool false

# ----------------------------------------------------------------
# NSGlobalDomain(General)
# ----------------------------------------------------------------
echo "- 🐤 NSGlobalDomain(General)"

# Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Set double-click a window's title bar to None
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "None"

# Set the accent color to green
# defaults write NSGlobalDomain AppleAccentColor -int 3

# Set the highlight color to green
# defaults write NSGlobalDomain AppleHighlightColor -string "0.752941 0.964706 0.678431 Green"

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

# ----------------------------------------------------------------
# Finder
# ----------------------------------------------------------------
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

# Automatically empty bin after 30 days
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

# ----------------------------------------------------------------
# Mission Control
# ----------------------------------------------------------------
echo "- 🪧 Mission Control" # killall Dock

# Choose whether to rearrange Spaces automatically.
defaults write com.apple.dock mru-spaces -bool false

# Group apps in Mission Control
defaults write com.apple.dock expose-group-apps -bool true

# ----------------------------------------------------------------
# Security & Privacy
# ----------------------------------------------------------------
echo "- 👮 Security & Privacy"

# Turn on Firewall
# (alf plist への直接書き込みは現行 macOS では反映されず、実際には無効のままだった。
#  socketfilterfw が現行のインターフェース)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# ----------------------------------------------------------------
# Keyboard
# ----------------------------------------------------------------
echo "- ⌨️ Keyboard"

# Set key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2

# Set delay until repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Fn key usage
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

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

# ----------------------------------------------------------------
# Key Remapping
# ----------------------------------------------------------------
echo "- 🔄 Key Remapping"

local_keymap_plist="$HOME/Library/LaunchAgents/local.keymap.plist"
launchctl bootout "gui/$UID" "$local_keymap_plist" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$local_keymap_plist"

# ----------------------------------------------------------------
# Downloads -> Desktop
# ----------------------------------------------------------------
# AirDrop の保存先は変更不可のため、~/Downloads にファイルが追加されたら
# ~/Desktop へ移動する LaunchAgent (fswatch + osascript) を登録する
echo "- 📥 Downloads -> Desktop"

local_d2d_plist="$HOME/Library/LaunchAgents/local.downloads-to-desktop.plist"
launchctl bootout "gui/$UID" "$local_d2d_plist" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$local_d2d_plist"

# ----------------------------------------------------------------
# Raycast backup
# ----------------------------------------------------------------
# 手動 export を fswatch で検知し、dotfiles 更新 PR と結果通知を作る
echo "- 💾 Raycast backup"

local_raycast_backup_plist="$HOME/Library/LaunchAgents/local.raycast-backup.plist"
launchctl bootout "gui/$UID" "$local_raycast_backup_plist" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$local_raycast_backup_plist"

# ----------------------------------------------------------------
# Network
# ----------------------------------------------------------------
echo "- 📡 Network"
# 設定確認したい時は次のコマンド`networksetup -getdnsservers "Wi-Fi"`
networksetup -setdnsservers Wi-Fi 2606:4700:4700::1111 2606:4700:4700::1001 1.1.1.1 1.0.0.1 || true

# ----------------------------------------------------------------
# Trackpad
# ----------------------------------------------------------------
echo "- 🖲 Trackpad"

# Haptic feedback => 0: Light 1: Medium 2: Firm
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

# Tracking Speed => 0: Slow 3: Fast
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# Disable swipe between pages
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

# Disable Look up & detectors
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0

# ----------------------------------------------------------------
# Mouse
# ----------------------------------------------------------------
echo "- 🖱 Mouse"

# Tracking Speed => 0: Slow 3: Fast
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3

# ----------------------------------------------------------------
# Display
# ----------------------------------------------------------------
echo "- 🖥 Display"

# Nightshift https://github.com/smudge/nightlight
if command -v nightlight >/dev/null 2>&1; then
  nightlight on
  nightlight schedule 7:00 6:59
fi

# Sidecar Settings
defaults write com.apple.sidecar.display doubleTapEnabled -bool true
defaults write com.apple.sidecar.display showTouchbar -bool false
defaults write com.apple.sidecar.display sidebarShown -bool false

# Delete Hot Corners
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 1048576

# ----------------------------------------------------------------
# Simulator
# ----------------------------------------------------------------
echo '- 📱 Simulator'

# Simulator lifetime 'When Simulator starts boot the most recently used simulator': off
defaults write com.apple.iphonesimulator StartLastDeviceOnLaunch -int 0

# ----------------------------------------------------------------
# TouchID - Sudo
# ----------------------------------------------------------------
echo '- 👆 TouchID'
if [ "${CI:-false}" = "false" ]; then
  sed -e 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local
fi

# ----------------------------------------------------------------
# Remote Login
# ----------------------------------------------------------------
echo '- 📡 Remote Login'
sudo launchctl load -w \
  /System/Library/LaunchDaemons/ssh.plist
sudo launchctl list com.openssh.sshd

# ----------------------------------------------------------------
# Cursor
# ----------------------------------------------------------------
# Ensure the directory exists
mkdir -p "$HOME/Library/Application Support/Cursor/User/"

ln -sf "$HOME/Library/Application Support/Code/User/keybindings.json" "$HOME/Library/Application Support/Cursor/User/"
ln -sf "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Cursor/User/"

snippets_dir="$HOME/Library/Application Support/Cursor/User/snippets"
if [ -d "$snippets_dir" ]; then
  rm -rf "$snippets_dir"
fi
ln -sf "$HOME/Library/Application Support/Code/User/snippets" "$snippets_dir"

# ----------------------------------------------------------------
# Loginwindow
# ----------------------------------------------------------------
echo '- 🪟 window'

# Disable relaunch apps on login
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false

# ----------------------------------------------------------------
# Killall
# ----------------------------------------------------------------
echo "- 👼 Killall..."

killall Dock
killall Finder
killall SystemUIServer
# cfprefsd helps an app or the system to read or write to preference files.
# killall は対象プロセスが居ないと exit 1 になり set -e で終盤に死ぬため握りつぶす
sudo killall cfprefsd || true
sudo killall corebrightnessd || true

echo "💻 MacOS setup is complete 🎉"
