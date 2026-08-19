---
status: accepted
date: 2026-07-30
---

# Mac App Store アプリは mas で管理しない

## 背景と課題

brew bundle の cleanup は、Brewfile の mas エントリの数で振る舞いが変わる。

```text
mas エントリ 0 件     → mas の cleanup 自体をスキップする
mas エントリ 1 件以上 → Brewfile に書いていないインストール済み MAS アプリを全部アンインストール対象にする
```

過去にこの巻き添えで事故が起き、[#1125](https://github.com/nozomiishii/dotfiles/pull/1125) で `--no-mas` ガードを入れた。

その後 [#1195](https://github.com/nozomiishii/dotfiles/pull/1195) で install と cleanup を `brew bundle --cleanup` に一体化した結果、ガードの `HOMEBREW_BUNDLE_CLEANUP_NO_MAS` はこの経路では読まれなくなっていた (Homebrew 6.0.12 のソースで確認)。実害が出ていないのは `mas uninstall` が root 必須で毎回失敗するためで、偶然守られているだけだった。

## 検討した選択肢

- Brewfile に mas エントリを置き、`HOMEBREW_BUNDLE_CLEANUP_NO_MAS` でガードする: `brew bundle --cleanup` の経路では読まれず、ガードとして効かない
- Brewfile から mas エントリを外し、MAS アプリは App Store から手動で入れる: エントリが 0 件なら cleanup は MAS アプリに触れない

## 決定

- Brewfile から mas エントリと mas 本体を削除し、MAS アプリ (Kindle・LINE・Xcode 等) は App Store から手動でインストールする
- Safari 拡張は Safari 設定の「デバイス間で共有」に表示されるものを都度インストールする
- homebrew.sh の `HOMEBREW_BUNDLE_CLEANUP_NO_MAS` も削除する

## 結果

### 良くなったこと

- Brewfile に mas エントリを書かない限り、cleanup が MAS アプリを巻き添えにする経路は構造的になくなる

### 引き受けたコスト

- 新しいマシンでは MAS アプリの分だけ手動インストールが残る

### 保留した論点

- mas 管理を再導入する場合はこの ADR を supersede し、cleanup の無効化が実際に効く形 (単独の `brew bundle cleanup` サブコマンドに `--no-cleanup-mas` を明示する等) を用意する
