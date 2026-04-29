# CLAUDE.md

このリポジトリで Claude Code (claude.ai/code) が作業する際のガイドラインです。

## よく使うコマンド

### 開発タスク

```bash
# Install Node.js dependencies
pnpm install

# Run tests (validates setup scripts)
pnpm test

# Format code with Prettier
pnpm run format

# Lint markdown files
pnpm run lint

# Run Prettier without writing changes
pnpm run prettier

# Test shell startup performance
./scripts/test_shell_startup_time.sh
```

### システムセットアップタスク

```bash
# Install/update Homebrew packages
make homebrew

# Configure macOS settings
make macos

# Set up programming toolchains (Node, Python, Ruby, Rust)
make toolchains

# Clone GitHub repositories
make repo

# Symlink dotfiles to home directory using GNU Stow
make link

# Complete installation (macOS/Linux)
./install.sh
```

## Git・GitHub 運用ルール

- **PR タイトルは英語で記述し、CI の semantic pull request チェックに従う。** 小文字で始める英数字・記号のみ、末尾にスペースを付けない。例: `feat(darwin): use launchctl for Remote Login`. 詳細は [.github/workflows/_pull-request.yaml](.github/workflows/_pull-request.yaml) を参照。
- **コミットメッセージ（subject と body）は英語で記述する。** PR 本文（description）は日本語でよい。
- **`home/.claude/statusline.sh` を変更する PR では、本文に修正前後の statusline 表示例を載せる。** ソース側にコメントで形式を残すと実装と乖離してメンテ漏れが起きるため、PR 本文側に書く。例:

  ````markdown
  ## Statusline before / after

  Before:

  ```
  dotfiles[shiny-munching-rose] git:(main) !1
  Opus 4.7 | 12% | surface:63 | [editor]
  ```

  After:

  ```
  dotfiles[shiny-munching-rose] git:(main) !1 cursor://file/Users/nozomiishii/dotfiles/.claude/worktrees/shiny-munching-rose
  Opus 4.7 | 12% | surface:63
  ```
  ````

## ポータビリティ

- **ユーザー名をハードコードしない。** dotfiles は複数の Mac で異なるユーザー名で運用されるため、plist・スクリプト・設定ファイルで `/Users/<name>/...` と直書きせず `$HOME` / `~` を使うこと。
  - LaunchAgent plist で `$HOME` 展開が必要な場合は `bash -l -c 'exec "$HOME/..."'` を経由する（参考: [home/Library/LaunchAgents/local.brew-update.plist](home/Library/LaunchAgents/local.brew-update.plist)）。
  - `bash -l` は `/etc/profile` 経由で `path_helper` を動かし、`/etc/paths.d/homebrew` の `/opt/homebrew/bin` を PATH に取り込む役割も兼ねる。

## アーキテクチャ概要

macOS と Linux で開発環境のセットアップを自動化する dotfiles リポジトリです。**GNU Stow** でシンボリックリンクを管理し、Make ターゲットで統一されたインターフェースを提供します。

### 主要コンポーネント

1. **`home/` ディレクトリ**: ホームディレクトリ構造に合わせて dotfiles を配置。`make link` 実行時に GNU Stow が `~` からこのディレクトリへのシンボリックリンクを作成する。

2. **`scripts/` ディレクトリ**: 自動化スクリプトを次のように整理
   - プラットフォーム別: `darwin/`（macOS 専用）
   - 用途別: `toolchains/`（言語セットアップ）

3. **Makefile**: 共通タスクの統一コマンドを提供するハブ。

4. **設定管理**:
   - シェル設定: `.zshrc`、`.zprofile`、`.zsh/` ディレクトリ
   - アプリ設定: 主に `.config/`（XDG Base Directory 準拠）
   - macOS アプリデータ: VS Code、Xcode 設定は `Library/` に配置
   - Claude Code 設定: `home/.claude/`（CLAUDE.md、settings.json、hooks、skills）

### 重要なパターン

- **Stow の使い方**: `home/` 内の dotfiles は GNU Stow で `~` にシンボリックリンクされる。`~/` 配下のファイルを新規作成・編集する前に、まず `home/` に対応するソースがないか確認し、あればそちらを編集すること。`~` に直接ファイルを作成・変更しない。特に `~/.claude/CLAUDE.md`（グローバル指示）の実体は `home/.claude/CLAUDE.md` にある。
- **パッケージ管理**: システムパッケージは Homebrew（`Brewfile`）、Node.js は pnpm を使用。
- **Git フック**: lefthook で管理（`lefthook.yaml` で設定）。
- **コード品質**: Prettier（フォーマット）、commitlint（コミットメッセージ）、markdownlint（ドキュメント）。

### 主要ファイル

- `install.sh`: 新規システムセットアップのエントリポイント
- `Brewfile`: Homebrew パッケージ、cask、Mac App Store アプリの定義
- `.github/workflows/test-install.yaml`: macOS と Ubuntu でのインストールテスト用 CI 設定
- `.mcp.json`: AI アシスタント連携用 MCP サーバー設定

### 新規設定の追加手順

1. `home/` 配下の適切なサブディレクトリに dotfiles を配置
2. `make link` でシンボリックリンクを作成
3. 新規ツールを追加する場合は `Brewfile` を更新
4. 新規スクリプトは命名規則に従い、適切な `scripts/` サブディレクトリに配置
