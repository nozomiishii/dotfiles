---
status: accepted
date: 2026-07-31
---

# Brewfile は 1 ファイルで管理する

## 背景と課題

Brewfile と Brewfile.optional の 2 ファイル構成では、cleanup の「残すリスト」が実行経路で食い違う。

```text
make homebrew
  → Brewfile + Brewfile.optional を適用。残すリストは両方

素の install.sh
  → Brewfile だけを --cleanup --force で適用。残すリストは Brewfile だけ
  → optional 導入済みのマシンで再実行すると optional のアプリが全部アンインストールされる
```

分割のもう 1 つの動機だった mas エントリの隔離は、[mas 管理の廃止](Mac%20App%20Store%20アプリは%20mas%20で管理しない.md)で不要になった。

## 検討した選択肢

- 2 ファイル構成を続ける: 経路ごとの食い違いが残る。分割の動機だった mas エントリの隔離はもう無い
- 重要と後からインストールで分ける (TODO にあった案): 分割が残るので、経路ごとの食い違いは解けない
- 1 ファイルに統合する: どの経路でも適用内容が同じになる

## 決定

Brewfile.optional の内容を Brewfile に統合し、`HOMEBREW_BUNDLE_INCLUDE_OPTIONAL` を廃止する。

macOS ローカル向けパッケージは `if OS.mac? && !ENV["CI"]` に置き、CI では入れない。

## 結果

### 良くなったこと

- install.sh と `make homebrew` の適用内容が一致し、どの経路でも巻き添え削除が起きない

### 引き受けたコスト

- 初回の install.sh は旧 optional 分 (Blender・Android Studio 等) も入れるため時間が延びる
- CI が入れるのはブロック外の共通 CLI のみ。macOS 向けパッケージの検証はローカルに任せる

### 保留した論点

- 分割を再導入する場合はこの ADR を supersede し、cleanup の残すリストを常に全ファイルの連結にする設計を用意する
