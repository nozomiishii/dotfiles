# Mac App Store アプリは mas で管理しない

Status: accepted
Date: 2026-07-30

## Context — 判断を迫られた状況

brew bundle の cleanup は、Brewfile に mas エントリが 1 件でもあると、Brewfile に書いていないインストール済み MAS アプリを全部アンインストール対象にする。0 件なら mas の cleanup 自体をスキップする。過去にこの巻き添えで事故が起き、[#1125](https://github.com/nozomiishii/dotfiles/pull/1125) で `--no-mas` ガードを入れた。

その後 [#1195](https://github.com/nozomiishii/dotfiles/pull/1195) で install と cleanup を `brew bundle --cleanup` に一体化した結果、ガードの `HOMEBREW_BUNDLE_CLEANUP_NO_MAS` はこの経路では読まれなくなっていた (Homebrew 6.0.12 のソースで確認)。実害が出ていないのは `mas uninstall` が root 必須で毎回失敗するためで、偶然守られているだけだった。

## Decision — 決めたこと

- Brewfile から mas エントリと mas 本体を削除し、MAS アプリ (Kindle・LINE・Xcode 等) は App Store から手動でインストールする
- Safari 拡張は Safari 設定の「デバイス間で共有」に表示されるものを都度インストールする
- homebrew.sh の `HOMEBREW_BUNDLE_CLEANUP_NO_MAS` も削除する。mas エントリが 0 件なら cleanup は MAS アプリに触れない

## Consequences — 決定がもたらすもの

- 新しいマシンでは MAS アプリの分だけ手動インストールが残る
- Brewfile に mas エントリを書かない限り、cleanup が MAS アプリを巻き添えにする経路は構造的になくなる
- mas 管理を再導入する場合はこの ADR を supersede し、cleanup の無効化が実際に効く形 (単独の `brew bundle cleanup` サブコマンドに `--no-cleanup-mas` を明示する等) を用意する
