# dotfiles

<!-- Main Image -->
<br>
<div align="center">
  <img src="https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif" alt="Brow my mind" width="480" />
</div>
<br>

<!-- shields -->
<div align="center">
  <a target="_blank" href="https://open.vscode.dev/nozomiishii/dev">
    <img alt="Open in VSCode" src="https://img.shields.io/static/v1?logo=visualstudiocode&label=&message=Open%20in%20VSCode&labelColor=2c2c32&color=007acc&logoColor=007acc">
  </a>
  <a target="_blank" href="https://twitter.com/nozomiishii_dev">
    <img alt="twitter" src="https://img.shields.io/twitter/follow/nozomiishii_dev?style=social&label=Follow">
  </a>
</div>
<br>

- [📦 New Macbook? Awesome!!](#new-macbook?)
  - [Install](#install)
  - [Install Manually](#install-manually)
  - [App preferences](#app-preferences)
- [👨🏻‍🍳 Customize](#customize)
- [👨🏻‍🏭 Maintenance](#maintenance)
- [🔫 Troubleshooting](#troubleshooting)
- [👼 Reinstall macOS](#reinstall-macos)
- [🙌 References](#references)

<a id="new-macbook?"></a>

## 📦 New Macbook? Awesome

Turn On and Follow the guide

- Full Name: Nozomi Ishii
- Account name: nozomiishii

⚠️ Skip the AppleID sign in until the home screen. it takes time. ⚠️

### Open Apple ID with Spotlight

```txt
  ⌘ + space Apple ID
```

Sign in your iCloud and App Store, when you get to the home screen.
(to get apps using mas command)

💡 If you can't use your personal apple ID on your company computer,
install xcode manually from the App Store.

### 🍎 Apple ID

- Edit your profile photo

- **☁️ iCloud**

  - Photos
  - iCloud Drive
  - Find My Mac
  - Stocks

### 🍏 App Store

```txt
  ⌘ + space App Store
```

- Login

<a id="install"></a>

## Install

Wait about 3 hours(Go grab some food and take a nap 🍕😪)

### Open Terminal with Spotlight

```txt
  ⌘ + space Terminal
```

Change shell to zsh

```shell
  chsh -s /bin/zsh
  echo $SHELL
```

```shell
  curl -L https://nozomiishii.dev/dotfiles/install | zsh
```

-L (--location): Enable redirection.

<a id="install-manually"></a>

## Install Manually

### Install xcode-select

```shell
  xcode-select --install
```

xcode-select: this Command Line Tools are required for Git and Homebrew

### Come to this page

```shell
  open https://nozomiishii.dev/dotfiles
```

### Clone

```shell
  cd ~ && git clone https://github.com/nozomiishii/dotfiles.git
```

### Brew Install

```shell
  ~/dotfiles/install -b
```

### 🔫 When permission is not set

```shell
  ls -l ~/dotfiles/install
```

```shell
  chmod +x ~/dotfiles/install
```

### 💻 MacOS setup

```shell
  ~/dotfiles/install -m
```

### 🗂 Symbolic Link

```shell
  ~/dotfiles/install -l
```

### 🧝🏻‍♀️ Apps setup

```shell
  ~/dotfiles/install -a
```

### 🌝 Environment setup(asdf)

```shell
  ~/dotfiles/install -e
```

### 🛋 Restart

```shell
  sudo reboot
```

<a id="app-preferences"></a>

## App preferences

### ⛓ Karabiner-Elements

- Login

### 🔑 1Password

- Preferences > Security > Unlock using >  
  Check "Touch ID"
- Preferences > General > Menu bar >  
  Uncheck "Show 1Password in the menu bar"
- Preferences > General > Keyboard shortcuts >  
  remove all shortcuts(because it conflicts with xcode)

### 🗂 Finder

- Rearrange the order of the sidebar

```txt
Finder Sidebar
 ┣ 📂Favorites
 ┃ ┣ 🌏Google Drive(My Drive)
 ┃ ┣ 🗃dotfiles
 ┃ ┣ 🏠$USER
 ┃ ┣ 🍎Applications
 ┃ ┗ 📖Desktop
 ┗ 📂Locations
```

### 🎩 Alfred

- Activate the license

- Preferences > Advanced > Set preferences folder... >  
  Select "~/dotfiles/apps/Alfred"

- Preferences > General >  
  Alfred Hotkey: ⌘ + Space

- Preferences > Features > Clipboard History > History > Clipboard History >  
  Check "Keep Plain Text"  
  Select "7 Days"

- Preferences > Features > Snippets >  
  Check "Automatically expand snippets by keyword"

- Preferences > Advanced >  
  Force Keyboard: ABC

### 🌏 Chrome

- Sign in
- Change Chrome to the Default Browser
- Log in 1PasswordX
- (Optional)

  - [Gmail notification](https://support.google.com/mail/answer/1075549?hl=ja&co=GENIE.Platform%3DDesktop)
  - [Show working hours on your calendar](https://support.google.com/a/users/answer/9308669)
  - [Send email to Slack](https://slack.com/help/articles/206819278-Send-emails-to-Slack#:~:text=address%20to%20confirm.-,Use%20an%20email%20add%2Don,-Gmail)

  - Extensions
    - [1Password](https://chrome.google.com/webstore/detail/1password-%E2%80%93-password-mana/aeblfdkhhhdcdjpifhhbdiojplfjncoa)
    - [Adblock for YouTube](https://chrome.google.com/webstore/detail/adblock-for-youtube/cmedhionkhpnakcndndgjdbohmhepckk)
    - [Fonts Ninja](https://chrome.google.com/webstore/detail/fonts-ninja/eljapbgkmlngdpckoiiibecpemleclhh)
    - [DeepL](https://chrome.google.com/webstore/detail/deepl-translate-beta-vers/cofdbpoegempjloogbagkncekinflcnj)
    - [Video Speed Controller](https://chrome.google.com/webstore/detail/video-speed-controller/nffaoalbilbmmfgbnbgppjihopabppdk)
    - [Gossip Site Blocker](https://chrome.google.com/webstore/detail/gossip-site-blocker/mjojhcmecfehllhcjcbhkkpohadogplk)
    - [GoFullPage](https://chrome.google.com/webstore/detail/gofullpage-full-page-scre/fdpohaocaechififmbbbbbknoalclacl)
    - [Amazing Searcher](https://chrome.google.com/webstore/detail/amazing-searcher/poheekmlppakdboaalpmhfpbmnefeokj)
    - [Open in VS Code (github1s.com)](https://chrome.google.com/webstore/detail/open-in-vs-code-github1sc/neloiopjjeflfnecdlajhopdlojlkhll)

### 🗿 fig

- Setup

### ☁️ google-drive

- Sign in and Sync

### 🐟 VSCode

- User Icon > Setting sync > Login >  
  Select "Marge"  
  ⚠️ Do NOT Select "Replace"
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: Activate VSCode Icons
- Add MonokaiPro License

### 😼 Generate SSHkey and Login gh

```shell
  ~/dotfiles/install -k
```

### 🦄 Clone repositories

```shell
  ~/dotfiles/install -c
```

### 🤵🏻‍♂️ Keyboard Maestro

- Register Keyboard Maestro... >  
  Activate the License
- Preferences... > Sync Marcos >  
  Select "~/dotfiles/apps/KeyboardMaestro"

### 🧹 Hazel

- License... >  
  Activate the License
- Folder > Rule Sync Settings... > Use existing sync file... >  
  Select "~/dotfiles/apps/Hazel"
- Preferences... > General >  
  Uncheck "Show Hazel in the menu bar"
- Preferences... > Trash >  
  Check "Delete files sitting in the Trash for more than 1 Day"

### 🎨 ColorSnapper2

- Activate the license
- General
  - Hotkeys:  
    Pick Color: ⌃ + ⌥ + C
  - Clipboard Format >
    Check "Choose from Colors & Formats after picking"
- Appearance
  - Magnification >
    15x
- Code Style

  - Hex >
    check "Uppercase"
  - CSS Hex >
    check "Uppercase"

### 🐘 TablePlus

- TablePlus >  
  Register license...

### 🐔 Slack

- Sign in

### 🔮 DeepL

- Sign in
- Set hotkey to  
  ⇧ + ⌘ + Space

### 🤡 yabai

```shell
  brew services restart yabai && brew services restart skhd
```

### 🫐 BLEUnlock

- Device: Select your device
- Unlock RSSI: -45dBm
- Lock RSSI: -55dBm
- Check 'Pause "Now Playing" while Locked'
- Check 'Use Screensaver to Lock'
- Check 'Launch at Login'

### 💻 System Preferences

- **🌃 Desktop & Screen Saver**

  - **Desktop**  
    Select your favorite image
  - **Screen Saver**  
    Select "Brooklyn" (might need go Preferences > Security & Privacy > General >  
    On the bottom side, select "Open Anyway")

- **🌐 Language & Region**

  - Add Japanese

- **🛎 Notifications & Focus**
  - Notifications
    - **Calendar, Notion, Slack**  
      Alert style: Alerts  
      Show in Notification Centre  
      Play sound for notification
    - **Xcode**  
      Banners

  - Focus
    - Uncheck "Share Focus Status"

- **👤 Users & Groups**

  - **Current User**  
    Edit Profile photo

- **🧚🏻‍♀️ Accessibility**

  - **Spoken Content**  
    Select and Download "Siri Voice 1(United Kingdom)"  
    Adjust Speaking Rate

- **👮🏻 Security & Privacy**

  - **FileVault**  
    Click the lock to make changes >  
    Turn on

- **⌨️ Keyboard**

  - **Input Sources**  
    Delete "Kotoeri"  
    Add "google-japanese-ime"

- **🖥 Displays**

  - **Arrangement**  
    Change "iPad display on left"

### 📅 Calendar

- Add Accounts
- Add Calendar on Widgets

### 🤖 Unity Hub

- Sign in
- Download lts

### 🦖 C\#

- [Unity setup for M1 Mac](https://gurutaka-log.com/unity-vscode-mac-setup)
- [Download Mono](https://www.mono-project.com/download/stable/#download-mac)

### 🐵 Blender

- Sign in
- Edit > Preferences > Add-ons > search "id" to find "System: Blender ID authentication" >  
  login!
- [Download Blender Cloud add-on](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip)
- Edit > Preferences > Add-ons > install >  
  install Add-on "blender_cloud-X.XX.addon.zip"  
   ⚠️ DO NOT UNZIP
- Edit > Preferences > Input > Keyboard >  
  Emulate Numpad

### 🐍 PyCharm

- Preferences > Editor > General > Font > Size >  
  Font Size: 14
- Plugins  
  Monokai Pro Theme

### 🐸 Android Studio

- Preferences > Editor > General > Font > Size >  
  Font Size: 14
- Plugins  
  Monokai Pro Theme

### 🍎 Xcode

- Add Account
- Preferences > Themes >  
  Monokai Pro
- Preferences > Navigation >  
  Command-click on Code: Jumps to definition

### 🦋 Affinity Designer

- [Download App](https://store.serif.com/en-gb/account/downloads/)  
  Activate the license

### 📞 Cisco Packet Tracer

- [Download](https://www.netacad.com/portal/resources/packet-tracer)

### 🕶 ngrok

- [Get Auth token](https://dashboard.ngrok.com/get-started/your-authtoken)

```shell
  ngrok authtoken <your_auth_token>
```

```shell
  ngrok http 3000
```

### 🚙 duet

- [Download](https://www.duetdisplay.com/)

### ⏱ Setup Time machine

- Menu bar > Time machine >  
  Backup

<a id="customize"></a>

## 👨🏻‍🍳 Customize

### How to add app to Brew file

Search the app

```shell
  brew search <app_name>
```

Check if it's an app you want to download.

```shell
  brew info <app_name>
```

### How to find the defaults command

```shell
  defaults read > before
  # change the config
  defaults read > after
  diff before after
```

### Search app plist

```shell
  ll ~/Library/Preferences/ | grep <app_name>
  # example
  ll ~/Library/Preferences/ | grep firefox
```

### NSGlobalDomain plist

```shell
  open ~/Library/Preferences/.GlobalPreferences.plist
```

### Read app config

```shell
  defaults read <app_name_plist>
  # example
  defaults read notion.id
```

### Symbolic link

```shell
  ln -nfs <New_linking_file> <Existing_linked_files>
  # example
  ln -nfs "$HOME/Google Drive/Settings/dotfiles/zshrc" "$HOME/.zshrc"
```

<a id="maintenance"></a>

## 👨🏻‍🏭 Maintenance

Clean unused homebrew dependencies up, and upgrade them

```shell
  brew bundle cleanup --force && brew cleanup && brew upgrade
```

## Check the performance of zsh

```shell
  for x in {1..10}; do time zsh -i -c exit;done
```

<a id="troubleshooting"></a>

## 🔫 Troubleshooting

- **Audio-related**  
  NVRAM Reset  
  Shut down and Restart with  
  `⌥ + ⌘ + P + R`  
  💡 NVRAM is a memory that saves its stored data regardless if the power is on or off.

- **Third-party app related**  
  Safe mode  
  Shut down and wait 10 seconds  
  Restart with `⇧`  
  💡Safe Mode temporarily disables any third-party applications and starts your device with default system apps.

<a id="reinstall-macos"></a>

## 👼 Reinstall macOS

1: Unpair

- System Preferences > Bluetooth >  
  Unpair Bluetooth devices

2: Clean up

- Delete SSH keys on Github, GitLab

3: Sign out your iCloud.

- System Preferences > Apple ID > iCloud >  
  Turn off "Find My Mac"
- System Preferences > Apple ID > Overview >  
  Sign Out...

4: Deactivate license

- **🐘 TablePlus**  
  TablePlus > Register license...

- **🎨 ColorSnapper2**  
  About ColorSnapper... >  
  Deactivate license

- **🧹 Hazel**  
  License... > Remove...

- **🎩 Alfred**  
  Preferences > Powerpack > View your license key >  
  Deactivate

5: Erase All Content

- Erase All Content - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- From the Apple menu  in the corner of your screen, choose System Preferences
- From the System Preferences menu in the menu bar, choose Erase All Content and Settings

<a id="references"></a>

## 🙌 References

### Tutorials

[Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)  
[dotfiles + GitHub を使って開発環境をコマンド１発で構築する方法](https://www.youtube.com/watch?v=QZr33TQnIRk&t=9s)

### Dotfiles

[Patrick McDonald - EIEIO](https://github.com/eieioxyz/dotfiles_macos)  
[Mathias Bynens](https://github.com/mathiasbynens/dotfiles)  
[Your unofficial guide to dotfiles on GitHub.](https://dotfiles.github.io/inspiration)  
[JunichiSugiura/dotfiles](https://github.com/JunichiSugiura/dotfiles)

### CheatSheets

[macOS defaults list](https://macos-defaults.com)  
[Homebrew | Basics Commands and Cheat sheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)

### Dotfiles managed with

- [GNU stow](https://www.gnu.org/software/stow/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [asdf](https://asdf-vm.com/#/)
- [antigen](https://github.com/zsh-users/antigen)

## License

MIT License

© 2021 - 2022 Nozomi Ishii
