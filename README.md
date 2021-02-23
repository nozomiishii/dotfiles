# Nozomi's dotfiles
```txt
  📦settings
    ┣ 📂Alfred
    ┗ 📂dotfiles
```


![Brow my mind](https://media.giphy.com/media/LqajRC2pU0Je8/giphy.gif)

## Installation 📦

1: Sign in your iCloud.

2: Generate ssh key
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

3: `xcode-select --install` (Command Line Tools are required for Git and Homebrew)

4: Go to the dotfiles  
Install google-backup-and-sync
```shell
  brew install google-backup-and-sync --no-quarantine
```
```shell
  cd ~/Google\ Drive/settings/dotfiles
```

or clone project(Save it on Google Drive or dropbox recommended)
```shell
  cd ~/Google\ Drive/settings && git clone git@github.com:nozomiishii/dotfiles.git 
```

5: Run  
if you haven't install apps at AppStore on your account, download it first. the mas command is not for a new apps.
```shell
  ./install
```

## Setup App config  ⚙️  
**🎩 Alfred**  
Preferences > Advanced > Set preferences folder... > Select "~/Google\ Drive/settings/Alfred"  

**🔖 Dash**  
Preferences > General > Syncing > Set Sync Folder... > Select "/Google\ Drive/settings/dotfiles/sync/Dash"  
Preferences > General > Syncing > Snippets > Snippet library location > Select "/Google\ Drive/settings/dotfiles/sync/Dash"　

**🔑 1Password**  
Preferences > Security > Unlock using > Check "Touch ID"  
Preferences > General > Keyboard shortcuts > remove all shortcuts(because it conflicts with xcode)  

**🎮 iTerm2**   
Preferences > General > Preferences > Load preferences from a custom folder or URL > Select "~/Google\ Drive/settings/dotfiles/sync/iTerm2"  
⚠️ Do NOT click "save now", before your data restored. Select "Manually" and reload iTerm2 first!!  

**📟 VSCode**    
User Icon > Setting sync > Login > Select "Marge"  
⚠️ Do NOT Select "Replace"  

**👩🏻‍🏫 DeepL**  
Hotkey: ⌥ + T  
(May need to restart your mac)   

**🧲 Tiles**    
Hotkeys:  
Fullscreen: ⌥ + ⌘ + F  
Half Left: ⌥ + ⌘ + ←  
Half Right: ⌥ + ⌘ + →  
Half Top: ⌥ + ⌘ + ↑  
Half Bottom: ⌥ + ⌘ + ↓  
Previous Display: ⌥ + ⌘ + A   
Preferences:  
General > Appearance > uncheck "Show Tiles in the menu bar"(May need check it, when you want uninstall Tiles)  

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
Energy Saver  
Energy Saver > Battery > uncheck "Slightly dim the display while on battery power"


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

## Commands 👨🏻‍🏭
Clean unused homebrew dependencies
```shell
  brew bundle cleanup
```
## UnInstall Homebrew 🍺
```shell
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
```

## TroubleShooting 🔫  
When permission denied
```shell
  chmod +x ./install
  chmod +x ./dotbot/bin/dotbot
```

## Reinstall macOS🦄    
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
[Erasing your Mac and reinstalling macOS.- Japanese](https://support.apple.com/ja-jp/HT201065) 
[Erasing your Mac and reinstalling macOS. - English](https://support.apple.com/en-gb/HT201065)  

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
[How to erase your Intel-based Mac - Japanese](https://support.apple.com/ja-jp/HT208496)  
[How to erase your Intel-based Mac - English](https://support.apple.com/en-gb/HT208496)  

- Continue with the initial setup or if you want to quit, press command "⌘ + Q"  


## References 🙌
### Tutorials
[Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish/?referralCode=445BE0B541C48FE85276)

### Dotfiles
[eieio](https://github.com/eieioxyz/dotfiles_macos) 

### CheatSheet
[macOS defaults list](https://macos-defaults.com/)  
[Homebrew | Basics Commands and Cheatsheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)
### Modules
[dotbot](https://github.com/anishathalye/dotbot) - Dotbot makes installing your dotfiles as easy as git clone $url && cd dotfiles && ./install, even on a freshly installed system!

### Packages
**brew**  
[bat](https://github.com/sharkdp/bat) - Cat(1) clone with syntax highlighting and Git integration.  
[exa](https://github.com/ogham/exa) - Modern replacement for ls.   
[git](https://git-scm.com/) - Distributed revision control system.  
[hub](https://github.com/github/hub) - Make working with GitHub easier.  
[mas](https://github.com/mas-cli/mas) - Simple command line interface for the Mac App Store.    
[rbenv](https://github.com/rbenv/rbenv) - Ruby version management.  


**cask**  
[brooklyn](https://github.com/pedrommcarrasco/Brooklyn) - Screen Saver by Pedro Carrasco.   
[spotify](https://www.spotify.com/) - Music streaming service.    
[blender](https://www.blender.org/) - Free and open-source 3D creation suite.  
[iterm2](https://www.iterm2.com/) - Terminal emulator as alternative to Apple's Terminal app.   
[postman](https://www.postman.com/) - Collaboration platform for API development.  
[vlc](https://www.videolan.org/vlc/) - Multimedia player.     
[discord](https://discord.com/) - Voice and text chat software.   
[alfred](https://www.alfredapp.com/) - Application launcher and productivity software.    
[dash](https://kapeli.com/dash) - API documentation browser and code snippet manager.  
[swiftformat-for-xcode](https://github.com/nicklockwood/SwiftFormat) - Reformatting Swift code.  
[google-backup-and-sync](https://www.google.com/intl/en_ca/drive/download/) - Access and sync your content from any device.  
[zoom](https://www.zoom.us/) - Video communication and virtual meeting platform.  
[duet](https://www.duetdisplay.com/) - Tool for using an iPad as a second display.  
[skype](https://www.skype.com/) - Video chat, voice call and instant messaging application.  
[kindle](https://www.amazon.com/gp/digital/fiona/kcp-landing-page) - Interface for reading and syncing eBooks.  
[visual-studio-code](https://code.visualstudio.com/) - Open-source code editor.  
[firefox-developer-edition](https://www.mozilla.org/firefox/developer/) - Mozilla Firefox Developer Edition.  
[deepl](https://www.deepl.com/) - Trains AIs to understand and translate texts.  
[figma](https://www.figma.com/) - Collaborative interface design tool.  
[unity-hub](https://unity3d.com/get-unity/download) - Management tool for Unity.  
[notion](https://www.notion.so/) - App to write, plan, collaborate, and get organized.  
[tiles](https://www.sempliva.com/tiles/) - Window manager.  
[Slack](https://slack.com/) - Team communication and collaboration software.  
[google-chrome](https://www.google.com/chrome/) - Web browser.  
[colorsnapper](https://colorsnapper.com/) - Color picking application.  
[google-japanese-ime](https://www.google.co.jp/ime/) - Google Japanese Input Method Editor.  


**mas**  
[1Password 7](https://1password.com/) - Password manager that keeps all passwords secure behind one password.  
[Yoink](https://eternalstorms.at/yoink/mac/) - Improved Drag and Drop.  
[PopClip](https://pilotmoon.com/popclip/) - Instant text actions on your Mac.  
[Xcode](https://developer.apple.com/xcode/) - Apple's integrated development environment.  
