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
**1: Sign in your iCloud. (to get apps using mas command)**  
If you want to use a non-private account, Install XCode from Appstore.

**2:Open terminal and install xcode-select**  
```shell
  xcode-select --install
```
xcode-select: this Command Line Tools are required for Git and Homebrew  

**3: Clone**  
```shell
  cd ~/Desktop && git clone https://github.com/nozomiishii/dotfiles.git && cd dotfiles
```
oh my zsh(you can't insert following command into dotbot, because ohmyzsh will be escaped once the download completed)
```shell
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**4: Run**  
```shell
  ./install
```
🔫 When permission denied
```shell
  chmod +x ./install ./dotbot/bin/dotbot ./setup/homebrew.zsh ./setup/node.zsh ./setup/mac.zsh
```

**5: Sing in and setup 1Password🔑**  
Preferences > Security > Unlock using > Check "Touch ID"  
Preferences > General > Keyboard shortcuts > remove all shortcuts(because it conflicts with xcode)  

**6: Sign in google-backup-and-sync**  
Sign in, clean up temporary dotfiles, and go to the directory  
```shell
  rm -rf ~/Desktop/dotfiles && cd ~/Google\ Drive/settings/dotfiles
```

**7: Setup Mac config 💻**  
Run　　
```shell
  ./setup/mac.zsh
```

**8: Setup App config ⚙️**  
**🎩 Alfred**  
Setting Sync
Preferences > Advanced > Set preferences folder... > Select "~/Google\ Drive/settings/Alfred"  
Alfred > General > Alfred Hotkey: ⌘ + Space  

**⌨️ Keyboard**  
Input Sources > Delete "Kotoeri"  
Input Sources > Add "google-japanese-ime"  

**⛩ Language & Region**  
Language & Region > + > Add "Japanese"

**🦄 Accessibility**  
Accessibility > Speech > System Voice > Update Siri Voice  

**🌏 Chrome**  
Sign in  
Change Chrome to the Default Browser

**📟 VSCode**    
User Icon > Setting sync > Login > Select "Marge"  
⚠️ Do NOT Select "Replace"  
⇧ + ⌘ + P > Open command pallet > Icons: Activate VSCode Icons

**👩🏻‍🏫 DeepL**  
Hotkey: ⌥ + T  
(May need to restart your mac)   

**🎨 ColorSnapper2**  
Hotkeys:  
Pick Color: ⌃ + ⌘ + C  

**🐵 Blender**  
sign in  
Edit > Preferences > Add-ons > search "id" to find "System: Blender ID authentication" > login!
Download  
Get [Blender Cloud add-on](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip) 
Edit > Preferences > Add-ons > install > install Add-on "blender_cloud-X.XX.addon.zip"  
⚠️ DO NOT UNZIP

**💻 System Preferences**  
**Desktop Image**  
- Desktop & Screen Saver > Select your favorite image  

**Screen Saver**  
- Desktop & Screen Saver > Screen Saver > Select "Brooklyn" (might need go Preferences > Security & Privacy > General > On the bottom side, select "Open Anyway")  

**Display(Sidecar)**  
- Connect to iPad  
- System Preferences > Display > Arrangement > Change "iPad display on left"  

**Setup Time machine**  
Menu bar > Time machine > Backup  

**Finder**  
Rearrange the order of the sidebar  
```txt
Sidebar
 ┣ 📂Favourites
 ┃ ┣ 🌏Google Drive
 ┃ ┣ 🏠$USER
 ┃ ┣ 🍎Applications
 ┃ ┣ 💆🏻‍♂️Downloads
 ┃ ┗ 📖Desktop
 ┗ 📂Locations
```

**🚀 Launchpad Manager**  
Restore app locations on Launchpad  
Launchpad Manager > Register Launchpad Manager > Enter License Key  

## Generate ssh key🔓
Generate 
```ssh
  mkdir -p ~/.ssh && ssh-keygen -t ed25519 -o -a 100 -f ~/.ssh/id_ed25519 -C "TYPE_YOUR_EMAIL@HERE.com"
```
Copy ssh key and set up on github
```ssh
  pbcopy < ~/.ssh/id_ed25519.pub
```
Check if it's working
```ssh
  ssh -T git@github.com
```
Save
```ssh
  ssh-add ~/.ssh/id_ed25519
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

**Read app config**
```shell
  defaults read <app_name_plist>
```
defaults read org.mozilla.firefoxdeveloperedition  

## Commands 👨🏻‍🏭
Clean unused homebrew dependencies
```shell
  brew bundle cleanup
```
## UnInstall Homebrew 🍺
```shell
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

## Reinstall macOS 👼  
1: Sign out your iCloud.  
System Preferences > Apple ID > iCloud > Turn off "Find My Mac"  
System Preferences > Apple ID > Overview > Sign Out...  

2: Deactivate license  
**🎩Alfred**  
Preferences > Powerpack > View your license key > Deactivate  
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
💡 NVRAM is a memory that saves its stored data regardless if the power is on or off.

- Erase your mac and reinstall 
Shutdown mac  
Start up from the built-in macOS Recovery system: ⌘ + R  or,    
Start up from macOS Recovery over the Internet: ⌥ + ⌘ + R  
💡Difference:
⌘ + R -> Original OS you using: Mojave => Mojave, Big Sur=> Big Sur  
⌥ + ⌘ + R -> The latest OS: Mojave => Big Sur, Big Sur=> Big Sur  
💡Option: Change Language => File > Choose Language  
Choose your prefer language before reinstall OS. (following setup using this language)  

- Erase  
How to erase your Intel-based Mac - [Japanese](https://support.apple.com/ja-jp/HT208496) | [English](https://support.apple.com/en-gb/HT208496)  

- Continue with the initial setup or if you want to quit, press command "⌘ + Q"  


## References 🙌
### Tutorials
[Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)

### Dotfiles  
[Your unofficial guide to dotfiles on GitHub.](https://dotfiles.github.io/inspiration)  
[eieio](https://github.com/eieioxyz/dotfiles_macos) 

### CheatSheets
[macOS defaults list](https://macos-defaults.com)  
[Homebrew | Basics Commands and Cheatsheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)
### Modules
[dotbot](https://github.com/anishathalye/dotbot) - Dotbot makes installing your dotfiles as easy as git clone $url && cd dotfiles && ./install, even on a freshly installed system!

## Todo
[TodoList](https://www.notion.so/Todos-8ca66180cd044648a0698f1c737c19a0)

## License
MIT License  
© Nozomi Ishii
