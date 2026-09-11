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
mise --cd "$HOME/Code/nozomiishii/dotfiles" run repo
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
