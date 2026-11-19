#!/bin/bash
# Claude Code on the web / Codex Cloud の Setup script 欄に貼る:
#   curl -fsSL https://raw.githubusercontent.com/nozomiishii/dotfiles/main/scripts/cloud/setup.sh | bash
set -euo pipefail

bundle_dir=$(mktemp -d)
trap 'rm -rf -- "$bundle_dir"' EXIT
cd "$bundle_dir"
curl -fsSL "https://nozomiishii.github.io/dotfiles/cloud-setup.tar.gz" | tar xz

# Claude Code
mkdir -p ~/.claude
jq 'del(.statusLine, .sandbox)' home/.claude/settings.json >~/.claude/settings.json

# Codex
mkdir -p ~/.codex
cp home/AGENTS.md ~/.codex/AGENTS.md

# Agents (skills)
mkdir -p ~/.agents ~/.claude/skills
manifest="$HOME/.agents/.dotfiles-cloud-skill-files"
if [[ -f "$manifest" ]]; then
  while IFS= read -r -d '' path; do
    [[ "$path" == ./* && "/$path/" != */../* ]] || exit 1
    for dest in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
      if [[ -d "home/.agents/skills/$path" && -d "$dest/$path" ]] ||
         [[ -f "home/.agents/skills/$path" && -f "$dest/$path" ]]; then continue; fi
      root=$(cd -P -- "$dest" && pwd -P) || continue
      parent=$(cd -P -- "$dest/${path%/*}" 2>/dev/null && pwd -P) || continue
      [[ "$parent/" == "$root/"* ]] || continue
      if [[ -d "$dest/$path" && ! -L "$dest/$path" ]]; then
        rmdir -- "$dest/$path" 2>/dev/null || true
      else
        rm -f -- "$dest/$path"
      fi
    done
  done < "$manifest"
fi
cp -R home/.agents/. ~/.agents/
cp -R home/.agents/skills/. ~/.claude/skills/
next_manifest=$(mktemp "${manifest}.XXXXXX")
(cd home/.agents/skills && find . -depth -mindepth 1 -print0) > "$next_manifest"
mv -f -- "$next_manifest" "$manifest"

# mise
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
fi
