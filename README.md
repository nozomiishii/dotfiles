# Nozomi's dotfiles

```txt
  📦Settings
    ┣ 📂Alfred
    ┣ 📂Dash
    ┣ 📂LaunchpadManager
    ┗ 📂dotfiles
```

![Brow my mind](https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif)

## Installation 📦

**1: Sign in your iCloud and App Store. (to get apps using mas command)**  
If you want to use a non-private account, Install Xcode from App Store.

**2:Open terminal and install xcode-select**

```shell
  xcode-select --install
```

xcode-select: this Command Line Tools are required for Git and Homebrew

**3: Clone**  
Come to this page

```shell
  open https://github.com/nozomiishii/dotfiles
```

```shell
  cd ~/Desktop && git clone https://github.com/nozomiishii/dotfiles.git && cd dotfiles
```

oh my zsh(you can't insert following command into dotbot, because the process will exit by oh my zsh once the download completed)

```shell
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**4: Run**  
Check the permissions

```shell
  ls -l
```

Install applications and open Backup and Sync and 1Password

```shell
  ./setup/homebrew.zsh && open -a Backup\ and\ Sync && open -a 1Password\ 7
```

🔫 When permission denied

```shell
  chmod +x ./install ./dotbot/bin/dotbot ./setup/homebrew.zsh ./setup/node.zsh ./setup/mac.zsh
```

**5: Sign in and setup 1Password🔑**  
Preferences > Security > Unlock using > Check "Touch ID"  
Preferences > General > Keyboard shortcuts > remove all shortcuts(because it conflicts with xcode)

**6: Sign in google-backup-and-sync☁️**  
Sign in and Sync  
⚠️ Sync only **Settings** file (Downloading everything takes too much time.)

## While waiting for google-backup-and-sync to complete ⏳

**Finder**  
Rearrange the order of the sidebar

```txt
Sidebar
 ┣ 📂Favorites
 ┃ ┣ 🌏Google Drive
 ┃ ┣ 🏠$USER
 ┃ ┣ 🍎Applications
 ┃ ┣ 💆🏻‍♂️Downloads
 ┃ ┗ 📖Desktop
 ┗ 📂Locations
```

**💻 System Preferences**  
**Desktop Image**

- Desktop & Screen Saver > Select your favorite image

**Screen Saver**

- Desktop & Screen Saver > Screen Saver > Select "Brooklyn" (might need go Preferences > Security & Privacy > General > On the bottom side, select "Open Anyway")

**Login Icon**

- Users & Groups > Current User > Edit Profile photo

**Menu Bar**

- Dock & Menu Bar > Spotlight > uncheck "Show in Menu Bar"
- Dock & Menu Bar > Do Not Disturb > uncheck "Show in Menu Bar"
- Dock & Menu Bar > Screen Mirroring > uncheck "Show in Menu Bar"
- Dock & Menu Bar > Display > uncheck "Show in Menu Bar"
- Dock & Menu Bar > Sound > uncheck "Show in Menu Bar"
- Dock & Menu Bar > Now Playing > uncheck "Show in Menu Bar"

**Touch Bar**

- Extensions > Touch Bar > Customize  
  Volume Slider | Mute | Brightness Slider

**🌏 Chrome**  
Sign in  
Change Chrome to the Default Browser  
Log in 1PasswordX

**⌨️ Keyboard**  
Input Sources > Delete "Kotoeri"  
Input Sources > Add "google-japanese-ime"

**🐟 VSCode**  
User Icon > Setting sync > Login > Select "Marge"  
⚠️ Do NOT Select "Replace"  
⇧ + ⌘ + P > Open command pallet > Icons: Activate VSCode Icons

**🍎 Xcode**  
Add Account  
Preferences > Themes > Monokai Pro
Preferences > Navigation > Command-click on Code: Jumps to definition

**🐵 Blender**  
sign in  
Edit > Preferences > Add-ons > search "id" to find "System: Blender ID authentication" > login!  
[Download Blender Cloud add-on](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip)  
Edit > Preferences > Add-ons > install > install Add-on "blender_cloud-X.XX.addon.zip"  
⚠️ DO NOT UNZIP  
Setup  
Edit > Preferences > Input > Keyboard > Emulate Numpad

## When the google-backup-and-sync is complete 🎉

Clean up temporary dotfiles, and go to the directory

```shell
  rm -rf ~/Desktop/dotfiles && cd ~/Google\ Drive/settings/dotfiles
```

Run

```shell
  ./install
```

### 💡Start synchronizing all remaining google-backup-and-sync

**⛓ Karabiner-Elements**  
Login

**🎩 Alfred**  
Activate the license  
Preferences > Advanced > Set preferences folder... > Select "~/Google\ Drive/settings/Alfred"  
Alfred > General > Alfred Hotkey: ⌘ + Space

**🦋 Affinity Designer**  
[Download App](https://store.serif.com/en-gb/account/downloads/)  
Activate the license

**👩🏻‍🏫 DeepL**  
Delete hotkeys

**🗣 Speech**  
System Preferences > Accessibility > Spoken Content > Select and Download "Siri Female(United Kingdom)"  
System Preferences > Accessibility > Spoken Content > Adjust Speaking Rate

**Hazel🧹**
License... > Activate the License  
Folder > Rule Sync Settings... > Use existing sync file... > Select "~/Google\ Drive/Settings/Hazel"

**🎨 ColorSnapper2**  
Activate the license  
Hotkeys:  
Pick Color: ⌃ + ⌘ + C

**🛻 Display(Sidecar)**

- Connect to iPad
- System Preferences > Display > Arrangement > Change "iPad display on left"

**⏱ Setup Time machine**  
Menu bar > Time machine > Backup

**🐔 Slack**  
Sign in

**📅 Calendar**  
Add Accounts  
Add Calendar on Widgets

**🐍 PyCharm**  
Font Size  
Preferences > Editor > General > Font > Size > 14  
Plugins  
Monokai Pro Theme

**🛎 Notifications**  
**Calendar, Notion, Slack**  
Alerts  
Show in Notification Centre  
Play sound for notification  
**Xcode**  
Banners

**🗳 VirtualBox**  
Setup  
[Virtual Box Images](https://www.osboxes.org/virtualbox-images/)  
[Kali Linux](https://www.kali.org/downloads/)

## Generate ssh key🔓

[Connecting to GitHub with SSH](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)

Generate

```shell
  ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
  eval "$(ssh-agent -s)"
```

config

```shell
  touch ~/.ssh/config
  open ~/.ssh/config
```

Setup config

```shell
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_rsa
```

Save

```shell
  ssh-add -K ~/.ssh/id_rsa
```

Copy ssh key and set up on github

```shell
  pbcopy < ~/.ssh/id_rsa.pub
```

Check if it works

```shell
  ssh -T git@github.com
```

The authenticity of host 'github.com (13.114.40.48)' can't be established.
RSA key fingerprint is SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8.
Are you sure you want to continue connecting (yes/no/[fingerprint])?

```shell
  yes
```

This is the expected result:

```txt
  Hi --------! You've successfully authenticated, but GitHub does not provide shell access
```

**💡 Just ignore Warning: Permanently added the RSA host key for IP address**

**😼 hub**  
Create Personal access token on Github.

```shell
  hub browse
```

github.com username: <user_name>  
github.com password: <personal_access_token>

## Customize 👨🏻‍🍳

**How to add app to Brew file**

Search the app

```shell
  brew search <app_name>
```

Check if it's an app you want to download.

```shell
  brew info <app_name>
```

**How to find the defaults command**

```shell
  defaults read > before
  # change the config
  defaults read > after
  diff before after
```

**Symbolic link**

```shell
  ln -s <original> <link>
```

ln -nfs "$HOME/Google Drive/settings/dotfiles/sync/Karabiner-Elements/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

**Search app plist**

```shell
  ll ~/Library/Preferences/ | grep <app_name>
```

ll ~/Library/Preferences/ | grep firefox

**NSGlobalDomain plist**

```shell
  open ~/Library/Preferences/.GlobalPreferences.plist
```

**Read app config**

```shell
  defaults read <app_name_plist>
```

defaults read notion.id

## Maintenance 👨🏻‍🏭

Clean unused homebrew dependencies, and upgrade them

```shell
  brew bundle cleanup --force && brew cleanup && brew upgrade
```

## UnInstall Homebrew 🍺

```shell
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

## Troubleshooting 🔫

**Audio-related**  
NVRAM Reset  
Shut down and Restart with  
`⌥ + ⌘ + P + R`  
💡 NVRAM is a memory that saves its stored data regardless if the power is on or off.

**Third-party app related**  
Safe mode  
Shut down and wait 10 seconds  
Restart with `⇧`  
💡Safe Mode temporarily disables any third-party applications and starts your device with default system apps.

## Reinstall macOS 👼

1: Sign out your iCloud.  
System Preferences > Apple ID > iCloud > Turn off "Find My Mac"  
System Preferences > Apple ID > Overview > Sign Out...

2: Deactivate license  
**🎩Alfred**  
Preferences > Powerpack > View your license key > Deactivate  
**Hazel🧹**
License... > Remove...  
**🎨ColorSnapper2**  
About ColorSnapper... > Deactivate license

3: Unpair  
System Preferences > Bluetooth > Unpair Bluetooth devices

4: Clean up  
Delete SSH keys on Github, GitLab

5: Reinstall  
Erasing your Mac and reinstalling macOS - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)

- NVRAM Reset  
  `⌥ + ⌘ + P + R`

- Erase your mac and reinstall
  Shutdown mac  
  Start up from the built-in macOS Recovery system: ⌘ + R or,  
  Start up from macOS Recovery over the Internet: ⌥ + ⌘ + R  
  💡Difference:
  ⌘ + R -> Original OS you using: Mojave => Mojave, Big Sur=> Big Sur  
  ⌥ + ⌘ + R -> The latest OS: Mojave => Big Sur, Big Sur=> Big Sur  
  💡Option: Change Language => File > Choose Language  
  Choose your prefer language before reinstall OS. (following setup using this language)

- Erase  
  How to erase your Intel-based Mac - [Japanese](https://support.apple.com/ja-jp/HT208496) | [English](https://support.apple.com/en-gb/HT208496)  
  💡You can quit Disk Utility using the command ⌘ + Q

- Continue with the initial setup or if you want to quit, press command "⌘ + Q"

## References 🙌

### Tutorials

[Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)

### Dotfiles

[Patrick McDonald - EIEIO](https://github.com/eieioxyz/dotfiles_macos)  
[Mathias Bynens](https://github.com/mathiasbynens/dotfiles)  
[Your unofficial guide to dotfiles on GitHub.](https://dotfiles.github.io/inspiration)

### CheatSheets

[macOS defaults list](https://macos-defaults.com)  
[Homebrew | Basics Commands and Cheat sheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)

### Modules

[dotbot](https://github.com/anishathalye/dotbot) - Dotbot makes installing your dotfiles as easy as git clone $url && cd dotfiles && ./install, even on a freshly installed system!

## License

MIT License

Copyright © 2021 Nozomi Ishii
