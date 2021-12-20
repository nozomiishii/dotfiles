# Nozomi's dotfiles

![Brow my mind](https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif)

## 📦 New Macbook? Awesome!!

Turn On and Follow the guide

- Full Name: Nozomi Ishii
- Account name: nozomiishii

**⚠️ Skip the AppleID signup until the home screen. it takes time. ⚠️**

**🍎 Sign in your iCloud and App Store, when you get to the home screen. (to get apps using mas command)**  
If you can't use your personal apple ID on your company computer, install xcode manually from the App Store.

**Open Terminal with Spotlight**

- ⌘ + space

## Run and wait approx. 1.5h (Go grab some eat🍕)

```shell
  curl -L https://nozomiishii.dev/dotfiles/install | zsh
```

-L (--location): Enable redirection.

## Install Manually

**Install xcode-select**

```shell
  xcode-select --install
```

xcode-select: this Command Line Tools are required for Git and Homebrew

**Come to this page**

```shell
  open https://nozomiishii.dev/dotfiles
```

**Clone**

```shell
  cd ~ && git clone https://github.com/nozomiishii/dotfiles.git
```

**Brew Install**

```shell
  ./dotfiles/install -b
```

**🔫 When permission is not set**

```shell
  ls -l ./dotfiles/install
```

```shell
  chmod +x ./dotfiles/install
```

**💻 MacOS setup**

```shell
  ./dotfiles/install -m
```

**🗂 Symbolic Link**

```shell
  ./dotfiles/install -l
```

**🧝🏻‍♀️ Apps setup**

```shell
  ./dotfiles/install -a
```

**🌝 Environment setup(asdf)**

```shell
  ./dotfiles/install -e
```

## App preferences

**⛓ Karabiner-Elements**

- Login

**🔑 1Password**

- Preferences > Security > Unlock using >  
  Check "Touch ID"
- Preferences > General > Menu bar >  
  Uncheck "Show 1Password in the menu bar"
- Preferences > General > Keyboard shortcuts >  
  remove all shortcuts(because it conflicts with xcode)

**🌏 Chrome**

- Sign in
- Change Chrome to the Default Browser
- Log in 1PasswordX

**😼 gh**

```shell
  gh auth login
```

**🎩 Alfred**

- Activate the license
- Preferences > Advanced > Set preferences folder... >  
  Select "~/dotfiles/apps/Alfred"
- Alfred > General >  
  Alfred Hotkey: ⌘ + Space

**🐟 VSCode**

- User Icon > Setting sync > Login >  
  Select "Marge"  
  ⚠️ Do NOT Select "Replace"
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: Activate VSCode Icons
- Add MonokaiPro License

**🧹 Hazel**

- License... > Activate the License
- Folder > Rule Sync Settings... > Use existing sync file... >  
  Select "~/dotfiles/apps/Hazel"

**🎨 ColorSnapper2**

- Activate the license
- Hotkeys:  
  Pick Color: ⌃ + ⌥ + C

**🐘 TablePlus**

- TablePlus >  
  Register license...

**🐔 Slack**

- Sign in

**🗂 Finder**

- Rearrange the order of the sidebar

```txt
Sidebar
 ┣ 📂Favorites
 ┃ ┣ 🌏Google Drive(My Drive)
 ┃ ┣ 🗃dotfiles
 ┃ ┣ 🏠$USER
 ┃ ┣ 🍎Applications
 ┃ ┣ 💆🏻‍♂️Downloads
 ┃ ┗ 📖Desktop
 ┗ 📂Locations
```

**💻 System Preferences**

- **🌃 Desktop & Screen Saver**

  - **Desktop**  
    Select your favorite image
  - **Screen Saver**  
    Select "Brooklyn" (might need go Preferences > Security & Privacy > General >  
    On the bottom side, select "Open Anyway")

- **🌐 Language & Region**

  - Add Japanese

- **🛎 Notifications & Focus**

  - **Calendar, Notion, Slack**  
    Alert style: Alerts  
    Show in Notification Centre  
    Play sound for notification
  - **Xcode**  
    Banners

- **👤 Users & Groups**

  - **Current User**  
    Edit Profile photo

- **🧚🏻‍♀️ Accessibility**

  - **Spoken Content**  
    Select and Download "Siri Female(United Kingdom)"  
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

**☁️ google-drive**

- Sign in and Sync

**📅 Calendar**

- Add Accounts
- Add Calendar on Widgets

**⏱ Setup Time machine**

- Menu bar > Time machine >  
  Backup

**🤖 Unity Hub**

- Sign in
- Download lts

**🐵 Blender**

- Sign in
- Edit > Preferences > Add-ons > search "id" to find "System: Blender ID authentication" >  
  login!
- [Download Blender Cloud add-on](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip)
- Edit > Preferences > Add-ons > install >  
  install Add-on "blender_cloud-X.XX.addon.zip"  
   ⚠️ DO NOT UNZIP
- Edit > Preferences > Input > Keyboard >  
  Emulate Numpad

**🐍 PyCharm**

- Preferences > Editor > General > Font > Size >  
  Font Size: 14
- Plugins  
  Monokai Pro Theme

**🐸 Android Studio**

- Preferences > Editor > General > Font > Size >  
  Font Size: 14
- Plugins  
  Monokai Pro Theme

**🍎 Xcode**

- Add Account
- Preferences > Themes >  
  Monokai Pro
- Preferences > Navigation >  
  Command-click on Code: Jumps to definition

**🦋 Affinity Designer**

- [Download App](https://store.serif.com/en-gb/account/downloads/)  
  Activate the license

**📞 Cisco Packet Tracer**

- [Download](https://www.netacad.com/portal/resources/packet-tracer)

**🕶 ngrok**

- [Get Auth token](https://dashboard.ngrok.com/get-started/your-authtoken)

```shell
  ngrok authtoken <your_auth_token>
```

**🛋 Restart**

```shell
  sudo reboot
```

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

**Search app plist**

```shell
  ll ~/Library/Preferences/ | grep <app_name>
  # example
  ll ~/Library/Preferences/ | grep firefox
```

**NSGlobalDomain plist**

```shell
  open ~/Library/Preferences/.GlobalPreferences.plist
```

**Read app config**

```shell
  defaults read <app_name_plist>
  # example
  defaults read notion.id
```

**Symbolic link**

```shell
  ln -nfs <New_linking_file> <Existing_linked_files>
  # example
  ln -nfs "$HOME/Google Drive/Settings/dotfiles/zshrc" "$HOME/.zshrc"
```

## Maintenance 👨🏻‍🏭

Clean unused homebrew dependencies up, and upgrade them

```shell
  brew bundle cleanup --force && brew cleanup && brew upgrade
```

**Check the performance of zsh**

```shell
  for x in {1..10}; do time zsh -i -c exit;done
```

## Troubleshooting 🔫

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

## Reinstall macOS 👼

1: Sign out your iCloud.

- System Preferences > Apple ID > iCloud >  
  Turn off "Find My Mac"
- System Preferences > Apple ID > Overview >  
  Sign Out...

2: Deactivate license

- **🎩 Alfred**  
  Preferences > Powerpack > View your license key >  
  Deactivate

- **🧹 Hazel**  
  License... > Remove...

- **🎨 ColorSnapper2**  
  About ColorSnapper... >  
  Deactivate license

- **🐘 TablePlus**  
  TablePlus > Register license...

3: Unpair

- System Preferences > Bluetooth >  
  Unpair Bluetooth devices

4: Clean up

- Delete SSH keys on Github, GitLab

5: Erase All Content

- Erase All Content - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- From the Apple menu  in the corner of your screen, choose System Preferences
- From the System Preferences menu in the menu bar, choose Erase All Content and Settings

## References 🙌

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

Copyright © 2021 Nozomi Ishii
