---
status: accepted
date: 2026-08-20
---

# Raycast export の保存先は repo 実体ディレクトリにする

## 背景と課題

Raycast 設定バックアップの監視先は、当初 stow が ~ に映す `~/.config/raycast/backup/` だった。Raycast の保存ダイアログは前回の保存場所を記憶するため、repo 実体のディレクトリへ保存すると検知されず、通知も出ないまま止まっていた。保存先の候補が 2 つ見えることが誤保存の原因。

Raycast にはファイルを置くだけで取り込まれる監視ディレクトリが無く、[import は UI 操作でしかできない](https://manual.raycast.com/import-export)。~ 側に export を置く必然性は無い。

## 検討した選択肢

- `~/.config/raycast/backup/` を監視する — dotfiles の通例に沿う。repo 実体へ保存すると検知されない。~ 側の固定名ファイルは symlink なので、symlink 除外と固定名 guard の二重防御でループを防げる
- repo 実体の `home/.config/raycast/backup/` を監視する — 保存先とコミット先が一致し、誤保存が起きない。固定名ファイルが通常ファイルになり、ループ防止が固定名 guard だけになる

## 決定

repo 実体の `home/.config/raycast/backup/` を監視する。

```
タイムスタンプ名の export を保存
  → watcher が検知
  → 一時 worktree で固定名 Raycast.rayconfig にして commit / push / PR
  → export を削除

PR をマージして pull
  → repo の Raycast.rayconfig が更新されイベント発火
  → 固定名 guard で除外 (ここで止まる)
```

## 結果

### 良くなったこと

- 保存先が 1 つになり、誤保存で何も起きない事故が消える
- 監視先とコミット先が同じパス定義から導出され、ハードコードは 1 箇所に留まる。repo の場所は watcher 自身の stow リンクから解決する

### 引き受けたコスト

- ループ防止が固定名 guard 1 つに依存する。guard を外すと pull のたびに再処理が走る。差分なし判定の経路は repo の固定名ファイルを working tree から削除する
- export は処理されるまで repo の untracked ファイルとして見える。`git clean -fd` を挟むと未処理の export が消える

### 保留した論点

- `~/.config/raycast/backup/` を残すか。Raycast は読まないので、置き続ける理由は薄い
