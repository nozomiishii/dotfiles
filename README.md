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

## Gist

Busy? Just run command below;)

```shell
curl -fsSL https://dotfiles.nozo.sh | bash
```

<!-- <details>
<summary>with full version of Brewfile</summary>

```shell
curl -fsSL https://dotfiles.nozo.sh | bash -s -- --full
``` -->

## Development

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/nozomiishii/dotfiles)

## Outline

- [📦 New Macbook? Awesome!!](#new-macbook?)
  - [Before installation](#before-installation)
  - [Install](#install)
  - [Install Manually](#install-manually)
  - [App preferences](#app-preferences)
- [👨🏻‍🍳 Customize](#customize)
- [🍴 Forking](#forking)
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
(to install apps from the App Store manually)

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

The [Brewfile](Brewfile) intentionally does not manage Mac App Store apps. Install the apps used on the previous Mac manually:

- 1Password for Safari
- AdBlock Pro
- Jump Desktop
- Kindle
- LINE
- Obsidian Web Clipper
- Remote Desktop
- Video Speed Controller
- Xcode

See [Why Mac App Store apps are not managed with mas](docs/decisions/Mac%20App%20Store%20アプリは%20mas%20で管理しない.md) for the cleanup behavior this avoids.

<a id="before-installation"></a>

## Before installation

### Review the settings changed by the installer

The installer makes the following changes. Back up any existing settings first if Migration Assistant or iCloud has already restored them.

- [symlink.sh](scripts/symlink.sh) replaces conflicting dotfiles with the repository versions.
- [homebrew.sh](scripts/homebrew.sh) removes Homebrew formulae and casks not listed in the Brewfile.
- [macos.sh](scripts/darwin/macos.sh) clears the Dock, disables sleep on AC power, uses Cloudflare DNS, turns on the firewall, and enables Remote Login (SSH).
- Whenever Downloads changes, the [Downloads LaunchAgent](home/.local/lib/downloads-to-desktop.applescript) moves every non-hidden item that is not a partial browser download to the Desktop and replaces items with the same name.

### Install the Xcode Command Line Tools

Use Apple's supported installer before running the dotfiles installer. See [Installing the command-line tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools).

```shell
xcode-select --install
```

Wait for the installation dialog to finish, then confirm that the active developer directory is available.

```shell
xcode-select -p
```

### Install Xcode

Install the full Xcode app from the App Store before running the dotfiles installer. Select it as the active developer directory and install its first-launch components. See [Configuring command-line tools settings](https://developer.apple.com/documentation/xcode/configuring-command-line-tools-settings) and [Downloading and installing additional Xcode components](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).

```shell
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

<a id="install"></a>

## Install

Wait about 3 hours(Go grab some food and take a nap 🍕😪)

### Open Terminal with Spotlight

```txt
  ⌘ + space Terminal
```

```shell
curl -fsSL https://dotfiles.nozo.sh | bash
```

-fsSL: -L follows the dotfiles.nozo.sh redirect, -f aborts on HTTP errors (so a broken response is never piped to bash), -sS hide progress but still show errors.

<a id="after-installation"></a>

### After installation

#### Reboot

Run `sudo reboot` to apply the settings.

#### Retry Homebrew if needed

Re-run the unified Homebrew installer if a package download was interrupted:

```shell
make -C "$HOME/Code/nozomiishii/dotfiles" homebrew
```

#### Optional always-on settings

[always_on.sh](scripts/darwin/always_on.sh) disables sleep, the screen saver, and the password requirement after the screen saver, and enables Wake on LAN. Run it only when all of those changes are wanted.

```shell
make -C "$HOME/Code/nozomiishii/dotfiles" always-on
```

<a id="1password-github"></a>

#### Set up 1Password for GitHub SSH

- Sign in to and unlock the 1Password desktop app.
- Open Settings > Developer and turn on `Use the SSH agent` and `Integrate with 1Password CLI`. See [1Password SSH Agent](https://www.1password.dev/ssh/agent/) and [1Password CLI app integration](https://www.1password.dev/cli/app-integration/).
- Recreate the selectors needed from the previous Mac in `~/.config/1Password/ssh/agent.toml`. This file is local to each Mac and is not synced by 1Password. See [SSH agent configuration](https://www.1password.dev/ssh/agent/config).
- Confirm that GitHub can use a key from the agent:

```shell
ssh -T git@github.com
```

On the first connection, verify the fingerprint against [GitHub's SSH key fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints) before accepting it. Confirm that the output includes `Hi nozomiishii!`. GitHub does not provide shell access, so this successful test normally exits with status 1.

#### Authenticate with GitHub and clone private repositories

The flags pin the SSH protocol, skip SSH key generation because keys live in the 1Password SSH Agent, and add the `notifications` scope used by the watch skill plus the `workflow` scope for updating GitHub Actions workflow files. Neither scope is included by default. The token is issued through the browser and stored in the macOS Keychain.

```shell
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web --scopes notifications,workflow
make -C "$HOME/Code/nozomiishii/dotfiles" repo
```

`make repo` pre-registers GitHub's public host keys in `~/.ssh/known_hosts`, fetched from the [GitHub meta API](https://docs.github.com/en/rest/meta/meta#get-apiversion-meta-information). It records only the server's public host key, never a private key.

<a id="install-manually"></a>

<details>
<summary>Install Manually</summary>

Complete the [Before installation](#before-installation) steps first.

### Come to this page

```shell
open https://nozomiishii.dev/dotfiles
```

### Clone

```shell
git clone https://github.com/nozomiishii/dotfiles.git ~/Code/nozomiishii/dotfiles
cd "$HOME/Code/nozomiishii/dotfiles"
```

### Install

```shell
./install.sh
```

### 🛋 Restart

```shell
sudo reboot
```

Then follow the [After installation](#after-installation) steps above.

</details>

<a id="app-preferences"></a>

## App preferences

### 🔑 1Password

- Preferences > Security > Unlock using >  
  Check "Touch ID"
- Preferences > General > Keyboard shortcuts >  
  Autofill: `⌥⇧X`
- Complete the [1Password setup for GitHub SSH](#1password-github) before cloning private repositories.

### 🌏 Chrome

- Sign in
- Change Chrome to the Default Browser
- Log in 1PasswordX
- (Optional)

  - [Gmail notification](https://support.google.com/mail/answer/1075549?hl=en&co=GENIE.Platform%3DDesktop)
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
    - [Linkumori (URLs Cleaner)](https://chromewebstore.google.com/detail/jchobbjgibcahbheicfocecmhocglkco)
      - Automatically removes tracking query parameters from URLs
    - [Amazon URL Shortener](https://chromewebstore.google.com/detail/bonkcfmjkpdnieejahndognlbogaikdg)
      - Shortens Amazon product URLs
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

### 🐟 VSCode

- User Icon > Setting sync > Login >  
  Select "Marge"  
  ⚠️ Do NOT Select "Replace"
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: Activate VSCode Icons
- Add MonokaiPro License

### 🤖 Codex

`~/.codex/config.toml` is not tracked by dotfiles. Until [openai/codex#14601](https://github.com/openai/codex/issues/14601) is resolved, Codex auto-writes machine-local state into this file (project `trust_level` with absolute paths, `model`, and more), making it unsuitable for version control. Following the [Codex configuration reference](https://developers.openai.com/codex/config-reference/#configtoml), set the TUI preference and block GitHub connector PR merges by hand. Restart Codex after saving:

```toml
# ~/.codex/config.toml
[tui]
alternate_screen = "always"

# Merge PRs manually; do not let the agent perform merges
[apps.github.tools."github.merge_pull_request"]
enabled = false

[apps.github.tools."github.enable_auto_merge"]
enabled = false
```

### 😼 SSH & Git

- Complete the [1Password and GitHub SSH setup](#1password-github).

### 🦄 Clone repositories

The clone command is included in the [1Password and GitHub SSH setup](#1password-github).

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

<a id="forking"></a>

## 🍴 Forking

This repo is tuned for [nozomiishii](https://github.com/nozomiishii)'s personal setup, so the GitHub username, email, fixed paths, personal Homebrew tap, and scoped npm packages are hard-coded throughout.

If you fork it, see [docs/forking.md](docs/forking.md) for the list of places to update.

<a id="maintenance&dev"></a>

## 👨🏻‍🏭 Maintenance & Dev

### Maintenance

Clean unused homebrew dependencies up, and upgrade them

```shell
make homebrew
```

Relink dotfiles after editing files under `home/`

```shell
make link
```

Reapply macOS system settings

```shell
make macos
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
