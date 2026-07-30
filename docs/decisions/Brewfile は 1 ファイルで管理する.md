# Brewfile は 1 ファイルで管理する

Status: accepted
Date: 2026-07-31

## Context — 判断を迫られた状況

Brewfile と Brewfile.optional の 2 ファイル構成では、cleanup の「残すリスト」が実行経路で食い違う。`make homebrew` は両方を適用するが、素の install.sh は Brewfile だけを `--cleanup --force` で適用するため、optional 導入済みのマシンで install.sh を再実行すると optional のアプリが全部アンインストールされる。分割のもう 1 つの動機だった mas エントリの隔離は、[mas 管理の廃止](Mac%20App%20Store%20アプリは%20mas%20で管理しない.md)で不要になった。

## Decision — 決めたこと

- Brewfile.optional の内容を Brewfile に統合し、`HOMEBREW_BUNDLE_INCLUDE_OPTIONAL` を廃止する
- 移した cask と qemu は `unless ENV["CI"]` ブロックに置き、CI に大きなアプリを入れない従来挙動を保つ
- TODO にあった「重要と後からインストールで分ける」案は採用しない

## Consequences — 決定がもたらすもの

- install.sh と `make homebrew` の適用内容が一致し、どの経路でも巻き添え削除が起きない
- 初回の install.sh は旧 optional 分 (Blender・Android Studio 等) も入れるため時間が延びる
- 分割を再導入する場合はこの ADR を supersede し、cleanup の残すリストを常に全ファイルの連結にする設計を用意する
