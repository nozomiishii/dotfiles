#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo -e "🐂 stow"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Drop macOS .DS_Store files macOS scatters into the package — otherwise
# stow would happily link them into $HOME on every restow.
find home -name '.DS_Store' -delete

# --adopt は衝突した実体ファイルを repo の working tree に吸収するため、home/ に
# 未コミットの変更があると、後段の git restore を待たず adopt 自身が上書きして消す。
# 破棄を防ぐため、adopt する前に home/ の未コミット変更を検出して中断する。
if ! git diff --quiet -- home || ! git diff --quiet --cached -- home; then
  echo "ERROR: home/ に未コミットの変更があります。stow --adopt で破棄されるため中断します。" >&2
  echo "       commit か stash してから再実行してください。" >&2
  git status --short -- home >&2
  exit 1
fi

# 外部ツールが実行時に書き込むディレクトリは、実 dir として先に用意してから
# stow を走らせる。まっさらなアカウントでは tree folding で repo 配下への
# folder-symlink に畳まれ、ssh-keygen の秘密鍵・Claude Code / Codex / VS Code の
# ランタイム状態・サードパーティの LaunchAgent が repo working tree に書き込まれて
# しまう。~/.local/bin は、あとで張る ln -sfn の書き込み先になるため同様。
runtime_dirs=(
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.config"
  "$HOME/.config/raycast"
  "$HOME/.local/bin"
  "$HOME/.ssh"
  "$HOME/Documents/superwhisper/modes"
  "$HOME/Library/Application Support/Code/User"
  "$HOME/Library/Developer/Xcode/UserData"
  "$HOME/Library/LaunchAgents"
)
mkdir -p "${runtime_dirs[@]}"
chmod 700 "$HOME/.ssh"

# repo を常に正とする。衝突する実体ファイルは --adopt で stow が吸収し（削除しない）、
# 直後に git restore で repo 版へ戻す。home/ は上のチェックでクリーンなので、
# restore が戻すのは adopt が吸収した分だけ。
stow --adopt --verbose --restow --target="$HOME" home
git restore home
