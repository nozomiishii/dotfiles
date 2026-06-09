#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
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

# ~/.local/bin を実 dir として先に用意してから stow を走らせる。tree folding で
# ~/.local/bin が repo 配下への folder-symlink に畳まれると、あとで張る ln -sfn の
# 書き込み先が repo working tree に入って次回 make link が止まる。
mkdir -p "$HOME/.local/bin"

# repo を常に正とする。衝突する実体ファイルは --adopt で stow が吸収し（削除しない）、
# 直後に git restore で repo 版へ戻す。home/ は上のチェックでクリーンなので、
# restore が戻すのは adopt が吸収した分だけ。
stow --adopt --verbose --restow --target="$HOME" home
git restore home

# 正本 AGENTS.md は home/.codex/AGENTS.md（Codex の定位置）に置き、Stow が
# ~/.codex/AGENTS.md に配る。Claude 側の ~/.claude/CLAUDE.md は home/.claude/CLAUDE.md
# に置いた repo 内 symlink（→ ../.codex/AGENTS.md）を Stow が配るので、ここでは何もしない。

# skills: 各 skill を Claude / Codex の skills dir へ。
# Codex の global skills は ~/.agents/skills（~/.codex/skills は読まれない）。
SKILLS_DIR="$HOME/.ai/skills"
if [ -d "$SKILLS_DIR" ]; then
  echo "Linking ~/.ai/skills to Claude and Codex..."
  mkdir -p "$HOME/.claude/skills" "$HOME/.agents/skills"
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    ln -sfn "$SKILLS_DIR/$name" "$HOME/.claude/skills/$name"
    ln -sfn "$SKILLS_DIR/$name" "$HOME/.agents/skills/$name"
  done
fi

# plist が指すための入口を ~/.local/bin に張る (Darwin のみ)。新しい launchd 入口を
# 増やす場合はこの配列に追加する。
if [[ "$(uname -s)" == "Darwin" ]]; then
  LOCAL_BIN_SCRIPTS=(brew_update.sh claude_insights.sh)
  for script in "${LOCAL_BIN_SCRIPTS[@]}"; do
    ln -sfn "$SCRIPT_DIR/scripts/darwin/$script" "$HOME/.local/bin/$script"
  done
fi
