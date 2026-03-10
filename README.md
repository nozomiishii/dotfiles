# dotfiles

<!-- Main Image -->
<br>
<div align="center">
  <img src="https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif" alt="Brow my mind" width="480" />
</div>
<div align="right">
  <small>via GIPHY</small>
</div>
<br>

<!-- shields -->
<div align="center">
  <a target="_blank" href="https://twitter.com/nozomiishii_dev">
    <img alt="twitter" src="https://img.shields.io/twitter/follow/nozomiishii_dev?style=social&label=Follow">
  </a>
</div>
<br>

## Gist

Busy? Just run command below;)

```shell
curl -L https://nozomiishii.dev/dotfiles/install | bash
```

<!-- <details>
<summary>with full version of Brewfile</summary>

```shell
curl -L https://nozomiishii.dev/dotfiles/install | bash -s -- --full
``` -->

<!-- これにするのが目標

```shell
curl -L dot.nozomiishii.dev | sh
``` -->

</details>

## Development

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/nozomiishii/dotfiles)

## Outline

- [📦 New Macbook? Awesome!!](#new-macbook?)
  - [Install](#install)
  - [Install Manually](#install-manually)
  - [App preferences](#app-preferences)
- [👨🏻‍🍳 Customize](#customize)
- [👨🏻‍🏭 Maintenance & Dev](#maintenance&dev)
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

💡 Can you not use your personal apple ID on your company computer?
Install xcode manually from the App Store.

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

```shell
curl -L https://nozomiishii.dev/dotfiles/install | bash
```

-L (--location): Enable redirection.

<a id="install-manually"></a>

<details>
<summary>Install Manually</summary>

### Install xcode-select

```shell
xcode-select --install
```

xcode-select: this command-line Tools are required for Git and Homebrew

### Come to this page

```shell
open https://nozomiishii.dev/dotfiles
```

### Clone

```shell
cd ~ && git clone https://github.com/nozomiishii/dotfiles.git
```

### Install

```shell
./install.sh
```

### 🛋 Restart

```shell
sudo reboot
```

</details>

<a id="app-preferences"></a>

## App preferences

### ⛓ Karabiner-Elements

- Login

### 🔑 1Password

- Preferences > Security > Unlock using >  
  Check "Touch ID"
- Preferences > General > Keyboard shortcuts >  
  Autofill: `⌥⇧X`
- Preferences > Developer > Check "Use the SSH agent"
- Preferences > Developer > Check "Integrate with 1Password CLI"
  - [Turn on the 1Password desktop app integration](https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration)

### 🌏 Chrome

- Sign in
- Change Chrome to the Default Browser
- Log in 1PasswordX
- (Optional)

  - [Gmail notification](https://support.google.com/mail/answer/1075549?hl=ja&co=GENIE.Platform%3DDesktop)
  - [Show working hours on your calendar](https://support.google.com/a/users/answer/9308669)
  - [Send email to Slack](https://slack.com/help/articles/206819278-Send-emails-to-Slack#:~:text=address%20to%20confirm.-,Use%20an%20email%20add%2Don,-Gmail)

  - Extensions
    - [1Password](https://chromewebstore.google.com/detail/aeblfdkhhhdcdjpifhhbdiojplfjncoa)
      - Shortcut
        - Activate the extension: `⇧⌘X`
    - [Adblock for YouTube](https://chromewebstore.google.com/detail/cmedhionkhpnakcndndgjdbohmhepckk)
    - [Responsive Viewer](https://chromewebstore.google.com/detail/inmopeiepgfljkpkidclfgbgbmfcennb)
    - [Fonts Ninja](https://chromewebstore.google.com/detail/eljapbgkmlngdpckoiiibecpemleclhh)
    - [DeepL](https://chromewebstore.google.com/detail/cofdbpoegempjloogbagkncekinflcnj)
    - [Video Speed Controller](https://chromewebstore.google.com/detail/nffaoalbilbmmfgbnbgppjihopabppdk)
    - [Youtube Transcript Extractor](https://chromewebstore.google.com/detail/lclpibfglbkghjkdmpjkgehcnadcffdl)
    - [Gossip Site Blocker](https://chromewebstore.google.com/detail/mjojhcmecfehllhcjcbhkkpohadogplk)
    - [GoFullPage](https://chromewebstore.google.com/detail/fdpohaocaechififmbbbbbknoalclacl)
    - [Amazing Searcher](https://chromewebstore.google.com/detail/poheekmlppakdboaalpmhfpbmnefeokj)
    - [GraphQL Network Inspector](https://chromewebstore.google.com/detail/ndlbedplllcgconngcnfmkadhokfaaln)
    - [Tweak New Twitter](https://chromewebstore.google.com/detail/kpmjjdhbcfebfjgdnpjagcndoelnidfj)
    - [I don't care about cookies](https://chromewebstore.google.com/detail/fihnjjcciajhdojfnbdddfaoknhalnja)
    - [Youtube filter](https://chromewebstore.google.com/detail/dfbfdjepofdfhdddfdggabjjndhiggji)
    - [Screenshot YouTube](https://chromewebstore.google.com/detail/gjoijpfmdhbjkkgnmahganhoinjjpohk)
    - [Requestly](https://chromewebstore.google.com/detail/mdnleldcmiljblolnjhpnblkcekpdkpa)
    - [Linkumori (URLs Cleaner) ](https://chromewebstore.google.com/detail/jchobbjgibcahbheicfocecmhocglkco)
      - URL のクエリパラメータを自動削除
    - [Amazon URL Shortener](https://chromewebstore.google.com/detail/bonkcfmjkpdnieejahndognlbogaikdg)
      - amazon の URL 短くしてくれる
    - [Speechify Text to Speech Voice Reader](https://chromewebstore.google.com/detail/ljflmlehinmoeknoonhibbjpldiijjmm)
      - Shortcut
        - Activate the extension: `⌃Q`
        - Play/Pause: `⌃Space`

### ☁️ google-drive

- Sign in and Sync

### 🗂 Finder

- Rearrange the order of the sidebar

```txt
Finder Sidebar
 ┣ 📂Favorites
 ┃ ┣ 🌏Google Drive(My Drive)
 ┃ ┣ 🏠$USER
 ┃ ┣ 🧙🏿‍♂️dotfiles
 ┃ ┣ 🍎Applications
 ┃ ┗ 📖Desktop
 ┗ 📂Locations
```

### 🚁 Raycast

- needs: Finder setup

- Sign in
- Import Settings from "~/dotfiles/src/configs/\_raycast/backup"

### 🐟 VSCode

- User Icon > Setting sync > Login >  
  Select "Marge"  
  ⚠️ Do NOT Select "Replace"
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: Activate VSCode Icons
- Add MonokaiPro License

### 😼 SSH & Git

- [Run gh auth login](https://cli.github.com/manual/)

### 🦄 Clone repositories

```shell
make repo
```

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
  Register license

### 🐔 Slack

- Sign in

### 🫐 BLEUnlock

- Device: Select your device
- Unlock RSSI: -60dBm
- Lock RSSI: -75dBm
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

  - Candidate window
    - Font size: 14
    - Uncheck: Full-width numeral characters

- **🖥 Displays**

  - **Arrangement**  
    Change "iPad display on left"

### 📅 Calendar

- Add Accounts
- Add Calendar on Widgets

### 🐵 Blender

- Sign in
- Edit > Preferences > Add-ons > search "ID" to find "System: Blender ID authentication" >  
  login!
- [Download Blender Cloud add-on](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip)
- Edit > Preferences > Add-ons > install >  
  install Add-on "blender_cloud-X.XX.addon.zip"  
   ⚠️ DO NOT UNZIP
- Edit > Preferences > Input > Keyboard >  
  Emulate Numpad

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

### ⏱ Setup Time machine

- Menu bar > Time machine >  
  Backup

<a id="customize"></a>

## 👨🏻‍🍳 Customize

### How to add app to Brewfile

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

<a id="maintenance&dev"></a>

## 👨🏻‍🏭 Maintenance & Dev

### Maintenance

Clean unused homebrew dependencies up, and upgrade them

```shell
	brew bundle --verbose --cleanup --file="./Brewfile"
	brew cleanup --verbose
```

### Dev

```shell
pnpm install
```

To use @prettier/ruby

```shell
gem install bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs
```

## Check the performance of zsh

```shell
for x in {1..10}; do time zsh -i -c exit; done
```

<a id="troubleshooting"></a>

## 🔫 Troubleshooting

- **Audio-related**  
  NVRAM Reset  
  Shut down and Restart with  
  `⌥ + ⌘ + P + R`  
  💡 NVRAM is a memory that saves its stored data regardless if the power is on or off

- **Third-party app related**  
  Safe mode  
  Shut down and wait 10 seconds  
  Restart with `⇧`  
  💡Safe Mode temporarily disables any third-party applications and starts your device with default system apps

<a id="reinstall-macos"></a>

## 👼 Reinstall macOS

1: Unpair

- System Preferences > Bluetooth >  
  Unpair Bluetooth devices

2: Clean up

- Delete SSH keys on GitHub, GitLab

3: Sign out your iCloud.

- System Preferences > Apple ID > iCloud >  
  Turn off "Find My Mac"
- System Preferences > Apple ID > Overview >  
  Sign Out

4: Deactivate license

- **🐘 TablePlus**  
  TablePlus > Register license

- **🎨 ColorSnapper2**  
  About ColorSnapper... >  
  Deactivate license

- **🧹 Hazel**  
  License... > Remove

5: Erase All Content

- Erase All Content - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- From the Apple menu  in the corner of your screen, choose System Preferences
- From the System Preferences menu in the menu bar, choose Erase All Content and Settings

<a id="references"></a>

## 🙌 References

### Tutorials

- [Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)
- [dotfiles + GitHub を使って開発環境をコマンド１発で構築する方法](https://www.youtube.com/watch?v=QZr33TQnIRk&t=9s)

### Dotfiles

- [Patrick McDonald - EIEIO](https://github.com/eieioxyz/dotfiles_macos)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Your unofficial guide to dotfiles on GitHub.](https://dotfiles.github.io/inspiration)
- [JunichiSugiura/dotfiles](https://github.com/JunichiSugiura/dotfiles)

### CheatSheets

- [macOS defaults list](https://macos-defaults.com)
- [Homebrew | Basics Commands and Cheat sheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)

### Dotfiles managed with

- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)

## License

MIT License

© 2021 Nozomi Ishii
