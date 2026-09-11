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
mise --cd "$HOME/Code/nozomiishii/dotfiles" run repo
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
