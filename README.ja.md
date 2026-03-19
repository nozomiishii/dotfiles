# dotfiles

> [English version](README.md)

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

忙しい？下のコマンドをそのまま実行してください;)

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

## 開発

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/nozomiishii/dotfiles)

## 目次

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

電源を入れてガイドに従ってください

- Full Name: Nozomi Ishii
- Account name: nozomiishii

⚠️ ホーム画面が出るまで Apple ID のサインインはスキップしてください。時間がかかります。⚠️

### SpotlightでApple IDを開く

```txt
  ⌘ + space Apple ID
```

ホーム画面に到達したら、iCloud と App Store にサインインします。
(mas コマンドでアプリを取得するため)

💡 会社のPCで個人の Apple ID を使えませんか？
App Store から Xcode を手動でインストールしてください。

### 🍎 Apple ID

- プロフィール写真を編集

- **☁️ iCloud**

  - Photos
  - iCloud Drive
  - Find My Mac
  - Stocks

### 🍏 App Store

```txt
  ⌘ + space App Store
```

- ログイン

<a id="install"></a>

## Install

約3時間待ちます（食事をして、昼寝しましょう 🍕😪）

### SpotlightでTerminalを開く

```txt
  ⌘ + space Terminal
```

```shell
curl -L https://nozomiishii.dev/dotfiles/install | bash
```

-L (--location): リダイレクトを有効化

### After installation

1. **再起動**  
   設定を反映するために `sudo reboot` を実行します。

2. **(任意) Homebrew**  
   Brewfile.optional からパッケージをインストールするには：

   ```shell
   make homebrew
   ```

3. **(任意) 常時起動（スリープ無効）設定**  
   スリープを無効化して Wake on LAN などを使うために（[always_on.sh](scripts/darwin/always_on.sh)）：

   ```shell
   make always-on
   ```

4. **再起動後にプライベートリポジトリをクローン**  
   GitHub で認証したら、プライベートリポジトリをクローンします：

   ```shell
   gh auth login
   make repo
   ```

<a id="install-manually"></a>

<details>
<summary>手動でインストール</summary>

### xcode-select をインストール

```shell
xcode-select --install
```

xcode-select: このコマンドラインツールは Git と Homebrew に必要です。

### このページを開く

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

### 🛋 再起動

```shell
sudo reboot
```

その後、上の [After installation](#after-installation) の手順に従ってください。

</details>

<a id="app-preferences"></a>

## アプリの設定

### ⛓ Karabiner-Elements

- ログイン

### 🔑 1Password

- Preferences > Security > Unlock using >  
  「Touch ID」をチェック
- Preferences > General > Keyboard shortcuts >  
  自動入力: `⌥⇧X`
- Preferences > Developer > 「Use the SSH agent」をチェック
- Preferences > Developer > 「Integrate with 1Password CLI」をチェック
  - [Turn on the 1Password desktop app integration](https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration)

### 🌏 Chrome

- サインイン
- Chromeをデフォルトブラウザに変更
- 1PasswordX にログイン
- （任意）

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

- サインインして同期

### 🗂 Finder

- サイドバーの順序を並べ替え

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

- Finder のセットアップが必要

- サインイン
- 設定を "~/dotfiles/src/configs/\_raycast/backup" からインポート

### 🐟 VSCode

- User Icon > Setting sync > Login >  
  「Marge」を選択  
  ⚠️ 「Replace」を選択しない
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: VSCode Icons を有効化
- MonokaiPro のライセンスを追加

### 😼 SSH & Git

- [Run gh auth login](https://cli.github.com/manual/)

### 🦄 Clone repositories

```shell
make repo
```

### 🧹 Hazel

- License... >  
  ライセンスを有効化
- Folder > Rule Sync Settings... > Use existing sync file... >  
  Select "~/dotfiles/apps/Hazel"
- Preferences... > General >  
  「Show Hazel in the menu bar」のチェックを外す
- Preferences... > Trash >  
  「Delete files sitting in the Trash for more than 1 Day」をチェック

### 🎨 ColorSnapper2

- ライセンスを有効化
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
  ライセンスを登録

### 🐔 Slack

- サインイン

### 🫐 BLEUnlock

- Device: 対象デバイスを選択
- Unlock RSSI: -60dBm
- Lock RSSI: -75dBm
- 「Pause "Now Playing" while Locked」をチェック
- 「Use Screensaver to Lock」をチェック
- 「Launch at Login」をチェック

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

## 👨🏻‍🍳 カスタマイズ

### Brewfile にアプリを追加するには

アプリを検索します

```shell
  brew search <app_name>
```

ダウンロードしたいアプリかどうか確認します

```shell
  brew info <app_name>
```

### defaults コマンドの探し方

```shell
defaults read > before
# change the config
defaults read > after
diff before after
```

### アプリの plist を検索

```shell
  ll ~/Library/Preferences/ | grep <app_name>
  # example
  ll ~/Library/Preferences/ | grep firefox
```

### NSGlobalDomain の plist

```shell
open ~/Library/Preferences/.GlobalPreferences.plist
```

### アプリ設定を読む

```shell
  defaults read <app_name_plist>
  # example
  defaults read notion.id
```

### シンボリックリンク

```shell
  ln -nfs <New_linking_file> <Existing_linked_files>
  # example
  ln -nfs "$HOME/Google Drive/Settings/dotfiles/zshrc" "$HOME/.zshrc"
```

<a id="maintenance&dev"></a>

## 👨🏻‍🏭 メンテナンス & 開発

### メンテナンス

不要になった Homebrew の依存関係を削除し、アップグレードします

```shell
	brew bundle --verbose --cleanup --file="./Brewfile"
	brew cleanup --verbose
```

### 開発

```shell
pnpm install
```

@prettier/ruby を使うには

```shell
gem install bundler prettier_print syntax_tree syntax_tree-haml syntax_tree-rbs
```

## zsh のパフォーマンスを確認

```shell
for x in {1..10}; do time zsh -i -c exit; done
```

<a id="troubleshooting"></a>

## 🔫 トラブルシューティング

- **オーディオ関連**  
  NVRAM リセット  
  シャットダウンして、次のキーで再起動します  
  `⌥ + ⌘ + P + R`  
  💡 NVRAM は、電源のオン/オフに関係なく保存されているデータを保持するメモリです

- **サードパーティアプリ関連**  
  セーフモード  
  シャットダウンして 10 秒待つ  
  `⇧` で再起動  
  💡 セーフモードはサードパーティアプリを一時的に無効化し、デフォルトのシステムアプリで起動します

<a id="reinstall-macos"></a>

## 👼 macOS を再インストール

1: ペア解除

- System Preferences > Bluetooth >  
  Bluetooth デバイスをペア解除

2: 後片付け

- GitHub / GitLab から SSH キーを削除

- 3: iCloud からサインアウト

- System Preferences > Apple ID > iCloud >  
  「Macを探す」をオフ
- System Preferences > Apple ID > Overview >  
  サインアウト

4: ライセンスを無効化

- **🐘 TablePlus**  
  TablePlus > ライセンスを登録

- **🎨 ColorSnapper2**  
  ColorSnapper の情報... >  
  ライセンスを無効化

- **🧹 Hazel**  
  ライセンス... > 削除

5: すべてのコンテンツを消去

- すべてのコンテンツを消去 - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- 画面左上の （Apple メニュー）から `システム設定` を選択
- メニューバーの `システム設定` から「すべてのコンテンツと設定を消去」を選択

<a id="references"></a>

## 🙌 参考

### チュートリアル

- [Dotfiles from Start to Finish-ish](https://www.udemy.com/course/dotfiles-from-start-to-finish-ish)
- [dotfiles + GitHub を使って開発環境をコマンド１発で構築する方法](https://www.youtube.com/watch?v=QZr33TQnIRk&t=9s)

### dotfiles

- [Patrick McDonald - EIEIO](https://github.com/eieioxyz/dotfiles_macos)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Your unofficial guide to dotfiles on GitHub.](https://dotfiles.github.io/inspiration)
- [JunichiSugiura/dotfiles](https://github.com/JunichiSugiura/dotfiles)

### チートシート

- [macOS defaults list](https://macos-defaults.com)
- [Homebrew | Basics Commands and Cheat sheet](https://dev.to/code2bits/homebrew---basics--cheatsheet-3a3n)

### dotfiles を管理しているもの

- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)

## ライセンス

MIT License

© 2021 Nozomi Ishii
