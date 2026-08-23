# Repository Guidelines

macOS の開発環境セットアップを自動化する dotfiles リポジトリ。`home/` 内の dotfiles は [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) で `~` にシンボリックリンクされる。

## 設定の更新
- `~/` 配下のファイルを新規作成・編集する前に、まず `home/` に対応するソースがないか確認し、あればそちらを編集すること
  - `mise run link` でシンボリックリンクを更新

## ポータビリティ
- ユーザー名をハードコードしない。
  - dotfiles は複数の Mac で異なるユーザー名で運用されるため、`/Users/<name>/...` と直書きせず `$HOME` または `~` を使うこと。
  - LaunchAgent plist で `$HOME` 展開が必要な場合は `bash -l -c 'exec "$HOME/..."'` を経由する

- repo の配置場所をハードコードしない。
  - 別マシンや別 worktree で repo の置き場が変わっても動く必要がある。`$HOME/dotfiles/...` のような repo 実体パスを外から名指ししない。
  - launchd plist や VS Code 設定など外部ツールからは `$HOME/.local/bin/<name>.sh` 経由で呼ぶ。実体は `home/.local/bin/` に置く。

