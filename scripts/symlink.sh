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

# repo を常に正とする。衝突する実体ファイルは --adopt で stow が吸収し
# （削除しない）、直後に git restore で repo 版へ戻してローカル内容は破棄する。
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
