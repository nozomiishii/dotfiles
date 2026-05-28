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

# repo を常に正とする。衝突する実体ファイルは --adopt で stow が吸収し（削除しない）、
# 直後に git restore で repo 版へ戻す。home/ は上のチェックでクリーンなので、
# restore が戻すのは adopt が吸収した分だけ。
stow --adopt --verbose --restow --target="$HOME" home
git restore home

SKILLS_DIR="$HOME/.config/skills"
if [ -d "$SKILLS_DIR" ]; then
  echo "Linking skills to Cursor, Claude Code, and Codex..."
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")

    mkdir -p "$HOME/.cursor/skills"
    ln -sfn "$SKILLS_DIR/$name" "$HOME/.cursor/skills/$name"

    mkdir -p "$HOME/.codex/skills"
    ln -sfn "$SKILLS_DIR/$name" "$HOME/.codex/skills/$name"

    mkdir -p "$HOME/.claude/commands"
    ln -sfn "$SKILLS_DIR/$name/SKILL.md" "$HOME/.claude/commands/$name.md"
  done
fi

# launchd から起動するスクリプトを ~/.local/bin に symlink する。plist は repo の
# 実体パスではなく $HOME/.local/bin/<name>.sh を指すので、repo の配置場所が変わって
# も plist の書き換えなしで追従する（SCRIPT_DIR 経由で常に repo 実体を指す）。
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
for script in brew_update.sh claude_insights.sh; do
  ln -sfn "$SCRIPT_DIR/scripts/darwin/$script" "$LOCAL_BIN/$script"
done
