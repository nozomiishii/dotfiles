# Repository Guidelines

macOS と Linux で開発環境のセットアップを自動化する dotfiles リポジトリ。`home/` 内の dotfiles は [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) で `~` にシンボリックリンクされる。

## ポータビリティ

- ユーザー名をハードコードしない。
  - dotfiles は複数の Mac で異なるユーザー名で運用されるため、`/Users/<name>/...` と直書きせず `$HOME` または `~` を使うこと。
  - LaunchAgent plist で `$HOME` 展開が必要な場合は `bash -l -c 'exec "$HOME/..."'` を経由する（参考: [home/Library/LaunchAgents/local.downloads-to-desktop.plist](home/Library/LaunchAgents/local.downloads-to-desktop.plist)）

- repo の配置場所をハードコードしない。
  - 別マシンや別 worktree で repo の置き場が変わっても動く必要がある。`$HOME/dotfiles/...` のような repo 実体パスを外から名指ししない。
  - launchd plist や VS Code 設定など外部ツールからは `$HOME/.local/bin/<name>.sh` 経由で呼ぶ。実体は `home/.local/bin/` に置く。


## 設定の更新

- `~/` 配下のファイルを新規作成・編集する前に、まず `home/` に対応するソースがないか確認し、あればそちらを編集すること
  - `make link` でシンボリックリンクを更新

## macOS のシステム設定
- [scripts/darwin/](scripts/darwin/)

## 言語ランタイム
- [scripts/toolchains/](scripts/toolchains/)

## Homebrew パッケージ
- [Brewfile](Brewfile)
- [Brewfile.optional](Brewfile.optional)

## 詳細ドキュメント

特定領域の作業時にだけ参照するドキュメント

- [statusline (`home/.claude/statusline.sh`) を修正・拡張する](docs/statusline.md)
- [このdotfilesをforkして使う](docs/forking.md)
