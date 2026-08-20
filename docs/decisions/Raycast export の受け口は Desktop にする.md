---
status: accepted
date: 2026-08-20
---

# Raycast export の受け口は Desktop にする

## 背景と課題

Raycast 設定バックアップの監視先は短期間で 2 回動いたが、どちらもコミット済みの実体ファイルと export の受け口が同居する構造で、検知されない場所への誤保存とループ防止の guard 依存を生んでいた。

Raycast にはファイルを置くだけで取り込まれる監視ディレクトリが無く、[import は UI 操作でしかできない](https://manual.raycast.com/import-export)。受け口は自前で決める必要がある。

## 検討した選択肢

- `~/.config/raycast/backup/` — stow 投影された実体と同居する。役割が 2 つ混ざり、symlink 除外と固定名 guard の二重防御が要る
- repo 実体の `home/.config/raycast/backup/` — 同居のまま git working tree に移るだけ。untracked ノイズが出て、`git clean -fd` が未処理の export を消す
- `~/Downloads` — downloads-to-desktop が全件 `~/Desktop` へ move するため、処理前に持ち去られる
- `~/Desktop` — 実体と同居しない中立の受け口。「作業待ちのものは Desktop に置く」運用と一致する

## 決定

`~/Desktop` を受け口にする。コミット済みの実体は置かない。

```
Desktop にタイムスタンプ名の export を保存
Downloads に誤って保存 → downloads-to-desktop が Desktop へ move
  → watcher が検知
  → 一時 worktree で固定名 Raycast.rayconfig にして commit / push / PR
  → export を削除 (Desktop から消える = 完了)

失敗したとき
  → 通知が出て export は Desktop に残る = 作業待ちとして見えたまま
```

固定名 guard は Desktop では発火しなくなるが、RAYCAST_EXPORT_DIR で監視先を実体のあるディレクトリへ向けられるため残す。

## 結果

### 良くなったこと

- 受け口に実体が存在せず、ループの経路が構造ごと消える
- fswatch の再帰監視が不要になる

### 引き受けたコスト

- launchd 配下の watcher の Desktop へのファイル操作は TCC で初回にブロックされる可能性があり、切り替え後に実 export での動作確認が要る
- Desktop 全体のイベントが watcher に届く。拡張子 .rayconfig 以外は捨てるだけで実害は無い

### 保留した論点

- `~/.config/raycast/backup/` の stow 投影を残すか。Raycast は読まないので、置き続ける理由は薄い
