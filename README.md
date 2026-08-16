# dotfiles

English | [日本語](README.ja.md)

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

## 📦 New Macbook? Awesome

### Install

```shell
curl -fsSL https://dotfiles.nozo.sh | bash
```

## After installation

Restart

```shell
sudo reboot
```

## Required app setup

- Raycast
  - Just get ⌘ space working for now. Want movement to be smooth first. Login etc. later.

- 1password
  - Preferences > General > Keyboard shortcuts > show password: ⌥⌘X

- Chrome
- ChatGPT
- Claude Code
- Jump Desktop

- Github login and download repositories

```shell
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web --scopes notifications,workflow
make -C "$HOME/Code/nozomiishii/dotfiles" repo
```

## Other app setup

### 💻 System Preferences

- Screen Saver settings
- Security & Privacy
  - FileVault  
    Click the lock to make changes > Turn on
- Time Machine settings

### 🫐 BLEUnlock

- Device: Select your device
- Unlock RSSI: -60dBm
- Lock RSSI: -75dBm
- Check 'Pause "Now Playing" while Locked'
- Check 'Use Screensaver to Lock'
- Check 'Launch at Login'

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

- SSH keys live in the 1Password SSH agent (nothing is stored on this machine), so there are no keys to delete
- (Optional) Revoke the GitHub CLI authorization in [GitHub Settings > Applications](https://github.com/settings/apps/authorizations) — note this invalidates gh tokens on every machine

3: Sign out your iCloud.

- System Preferences > Apple ID > iCloud >  
  Turn off "Find My Mac"
- System Preferences > Apple ID > Overview >  
  Sign Out

4: Deactivate license

- **🐘 TablePlus**  
  TablePlus > Register license

5: Erase All Content

- Erase All Content - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- From the Apple menu  in the corner of your screen, choose System Preferences
- From the System Preferences menu in the menu bar, choose Erase All Content and Settings

<a id="references"></a>

## 🙌 References

### Tutorials

- [Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)
- [How to set up a dev environment with one command using dotfiles + GitHub (Japanese)](https://www.youtube.com/watch?v=QZr33TQnIRk&t=9s)

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
