# CLAUDE.md

このリポジトリで Claude Code (claude.ai/code) が作業する際のガイドラインです。

## 言語

- **応答言語**: プラン、説明、返答は常に日本語で行う。コードやコマンド、技術用語はそのまま使用してよい。

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

- **PR のマージは必ずユーザーが手動で行う。** AI アシスタントが `gh pr merge` や GitHub API 経由でマージを実行してはならない。
- PR の作成・更新・push は許可するが、マージの最終判断は常にユーザーに委ねること。

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

### 重要なパターン

- **Stow の使い方**: `home/` 内の dotfiles は GNU Stow で `~` にシンボリックリンクされる。新規設定を追加する際は `~` に直接ファイルを作成しない。
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
