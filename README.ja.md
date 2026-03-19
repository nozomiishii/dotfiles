# dotfiles

[English](README.md)

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

忙しい？下のコマンドをそのまま実行してね;)

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

電源を入れたら、画面のガイドに沿って進めていきましょう

- Full Name: Nozomi Ishii
- Account name: nozomiishii

⚠️ Apple ID のサインインはホーム画面が表示されるまでスキップしてください。少し時間がかかります。⚠️

### SpotlightでApple IDを開く

```txt
  ⌘ + space Apple ID
```

ホーム画面が表示されたら、iCloud と App Store にサインインしてください。
（mas コマンドでアプリを取得するために必要です）

💡 会社の PC で個人の Apple ID が使えない場合は、
App Store から Xcode を手動でインストールしてください。

### 🍎 Apple ID

- プロフィール写真を設定しましょう

- ☁️ iCloud

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

だいたい 3 時間ほどかかります（ごはんを食べて、ひと眠りしましょう 🍕😪）

### SpotlightでTerminalを開く

```txt
  ⌘ + space Terminal
```

```shell
curl -L https://nozomiishii.dev/dotfiles/install | bash
```

-L (--location): リダイレクトを有効化

### インストール後の作業

1. 再起動  
   設定を反映するために `sudo reboot` を実行してください。

2. （任意）Homebrew  
   Brewfile.optional のパッケージもインストールしたい場合はこちら：

   ```shell
   make homebrew
   ```

3. （任意）常時起動設定  
   スリープを無効にして Wake on LAN などを使いたい方向けです（[always_on.sh](scripts/darwin/always_on.sh)）：

   ```shell
   make always-on
   ```

4. プライベートリポジトリのクローン  
   再起動が終わったら GitHub で認証して、プライベートリポジトリをクローンしましょう：

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

xcode-select: Git と Homebrew を使うために必要なコマンドラインツールです。

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

その後、上の[インストール後の作業](#after-installation)の手順に進んでください。

</details>

<a id="app-preferences"></a>

## アプリの設定

### ⛓ Karabiner-Elements

- ログインしてください

### 🔑 1Password

- Preferences > Security > Unlock using >  
  「Touch ID」にチェックを入れてください
- Preferences > General > Keyboard shortcuts >  
  自動入力のショートカット: `⌥⇧X`
- Preferences > Developer > 「Use the SSH agent」にチェック
- Preferences > Developer > 「Integrate with 1Password CLI」にチェック
  - [Turn on the 1Password desktop app integration](https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration)

### 🌏 Chrome

- サインインしてください
- Chrome をデフォルトブラウザに設定
- 1PasswordX にログイン
- （お好みで）

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

### ☁️ Google Drive

- サインインして同期してください

### 🗂 Finder

- サイドバーの順序をお好みで並べ替えましょう

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

- 先に Finder のセットアップを済ませてください

- サインイン
- "~/dotfiles/src/configs/\_raycast/backup" から設定をインポート

### 🐟 VSCode

- User Icon > Setting sync > Login >  
  「Marge」を選択してください  
  ⚠️ 「Replace」は選ばないようにしましょう
- ⇧ + ⌘ + P > Open command pallet >  
  Icons: VSCode Icons を有効化
- MonokaiPro のライセンスを追加してください

### 😼 SSH & Git

- [Run gh auth login](https://cli.github.com/manual/)

### 🦄 Clone repositories

```shell
make repo
```

### 🧹 Hazel

- License... >  
  ライセンスを有効化してください
- Folder > Rule Sync Settings... > Use existing sync file... >  
  "~/dotfiles/apps/Hazel" を選択
- Preferences... > General >  
  「Show Hazel in the menu bar」のチェックを外してください
- Preferences... > Trash >  
  「Delete files sitting in the Trash for more than 1 Day」にチェック

### 🎨 ColorSnapper2

- ライセンスを有効化してください
- General
  - Hotkeys:  
    Pick Color: ⌃ + ⌥ + C
  - Clipboard Format >
    「Choose from Colors & Formats after picking」にチェック
- Appearance
  - Magnification >
    15x
- Code Style
  - Hex >
    「Uppercase」にチェック
  - CSS Hex >
    「Uppercase」にチェック

### 🐘 TablePlus

- TablePlus >  
  ライセンスを登録してください

### 🐔 Slack

- サインインしてください

### 🫐 BLEUnlock

- Device: お使いのデバイスを選択
- Unlock RSSI: -60dBm
- Lock RSSI: -75dBm
- 「Pause "Now Playing" while Locked」にチェック
- 「Use Screensaver to Lock」にチェック
- 「Launch at Login」にチェック

### 💻 システム設定

- 🌃 デスクトップとスクリーンセーバ

  - デスクトップ  
    お好きな画像を選んでください
  - スクリーンセーバ  
    「Brooklyn」を選択します（Security & Privacy > General で「このまま開く」が必要な場合があります）

- 🌐 言語と地域

  - 日本語を追加してください

- 🛎 通知と集中モード

  - 通知

    - Calendar, Notion, Slack  
      通知スタイル: 通知（Alerts）  
      通知センターに表示  
      通知音を鳴らす
    - Xcode  
      バナー

  - 集中モード
    - 「集中モード状況を共有」のチェックを外してください

- 👤 ユーザとグループ

  - 現在のユーザ  
    プロフィール写真を設定しましょう

- 🧚🏻‍♀️ アクセシビリティ

  - 読み上げコンテンツ  
    「Siri Voice 1(United Kingdom)」を選択してダウンロードしてください  
    読み上げ速度もお好みで調整できます

- 👮🏻 セキュリティとプライバシー

  - FileVault  
    鍵アイコンをクリックして変更を許可 >  
    オンにしてください

- ⌨️ キーボード

  - 候補ウィンドウ
    - フォントサイズ: 14
    - 「全角数字」のチェックを外してください

- 🖥 ディスプレイ

  - 配置  
    iPad のディスプレイを左側に変更します

### 📅 カレンダー

- アカウントを追加してください
- ウィジェットにカレンダーを追加しましょう

### 🐵 Blender

- サインイン
- Edit > Preferences > Add-ons > 「ID」で検索して「System: Blender ID authentication」を見つける >  
  ログインしてください
- [Blender Cloud add-on をダウンロード](https://cloud.blender.org/r/downloads/blender_cloud-latest-addon.zip)
- Edit > Preferences > Add-ons > install >  
  「blender_cloud-X.XX.addon.zip」をインストール  
   ⚠️ 解凍しないでください
- Edit > Preferences > Input > Keyboard >  
  Emulate Numpad をオン

### 🐸 Android Studio

- Preferences > Editor > General > Font > Size >  
  フォントサイズ: 14
- Plugins  
  Monokai Pro Theme をインストール

### 🍎 Xcode

- アカウントを追加
- Preferences > Themes >  
  Monokai Pro を選択
- Preferences > Navigation >  
  Command-click on Code: Jumps to definition に変更

### ⏱ Time Machine のセットアップ

- メニューバー > Time Machine >  
  バックアップを開始しましょう

<a id="customize"></a>

## 👨🏻‍🍳 カスタマイズ

### Brewfile にアプリを追加するには

まずアプリを検索してみましょう

```shell
  brew search <app_name>
```

目当てのアプリかどうか、詳細を確認してください

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

使わなくなった Homebrew の依存パッケージを整理して、最新にアップグレードしましょう

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

- オーディオ関連のトラブル  
  NVRAM リセットをお試しください  
  シャットダウンして、次のキーを押しながら再起動します  
  `⌥ + ⌘ + P + R`  
  💡 NVRAM は電源のオン/オフに関わらずデータを保持するメモリです

- サードパーティアプリ関連のトラブル  
  セーフモードをお試しください  
  シャットダウンして 10 秒ほど待ち、`⇧` を押しながら再起動します  
  💡 セーフモードではサードパーティアプリが一時的に無効化され、デフォルトのシステムアプリだけで起動します

<a id="reinstall-macos"></a>

## 👼 macOS を再インストール

1: Bluetooth デバイスのペア解除

- System Preferences > Bluetooth >  
  登録済みの Bluetooth デバイスをすべてペア解除してください

2: 後片付け

- GitHub / GitLab に登録した SSH キーを削除してください

3: iCloud からサインアウト

- System Preferences > Apple ID > iCloud >  
  「Mac を探す」をオフにしてください
- System Preferences > Apple ID > Overview >  
  サインアウトしてください

4: ライセンスの無効化

- 🐘 TablePlus  
  TablePlus > ライセンスを登録（解除）

- 🎨 ColorSnapper2  
  About ColorSnapper... >  
  ライセンスを無効化してください

- 🧹 Hazel  
  License... > Remove

5: すべてのコンテンツを消去

- すべてのコンテンツを消去 - [Japanese](https://support.apple.com/ja-jp/HT201065) | [English](https://support.apple.com/en-gb/HT201065)
- 画面左上の Apple メニューから「システム設定」を開きます
- メニューバーの「システム設定」から「すべてのコンテンツと設定を消去」を選択してください

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
