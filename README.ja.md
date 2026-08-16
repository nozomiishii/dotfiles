# dotfiles

[English](README.md) | 日本語

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

## インストール後の作業

再起動

```shell
sudo reboot
```

## 必須アプリの設定

- Raycast
  - ⌘ spaceができるようにだけしとく。とりあえず移動をスムーズにしたい。ログインとかは別途する。

- 1password
  - Preferences > General > Keyboard shortcuts > show password: ⌥⌘X

- Chrome
- ChatGPT
- Claude Code
- Jump Desktop

- Github loginとレポジトリダウンロード

```shell
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --web --scopes notifications,workflow
make -C "$HOME/Code/nozomiishii/dotfiles" repo
```

## その他アプリの設定

### 💻 システム設定

- スクリーンセーバーの設定
- セキュリティとプライバシー
  - FileVault  
    鍵アイコンをクリックして変更を許可 > オン
- Time Machineの設定

### 🫐 BLEUnlock

- Device: デバイスを選択
- Unlock RSSI: -60dBm
- Lock RSSI: -75dBm
- 「Pause "Now Playing" while Locked」にチェック
- 「Use Screensaver to Lock」にチェック
- 「Launch at Login」にチェック

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

- SSH 鍵は 1Password SSH agent 管理でこのマシンには置いていないため、削除する鍵はありません
- （任意）[GitHub Settings > Applications](https://github.com/settings/apps/authorizations) で GitHub CLI の認可を失効できます。全マシンの gh トークンが無効になる点に注意してください

3: iCloud からサインアウト

- System Preferences > Apple ID > iCloud >  
  「Mac を探す」をオフにしてください
- System Preferences > Apple ID > Overview >  
  サインアウトしてください

4: ライセンスの無効化

- 🐘 TablePlus  
  TablePlus > ライセンスを登録（解除）

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
