#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# worktree から呼ばれても本体の home/ と mise.toml を参照する (mise.toml の link と同じ)
common="$(git -C "$SCRIPT_DIR" rev-parse --path-format=absolute --git-common-dir)"
if [[ "$common" != */.git ]]; then
  echo "Error: unexpected git common dir: ${common}" >&2
  exit 1
fi
repo_root="${common%/.git}"

echo "🧩 external skills"

mise -C "$repo_root" install --locked github:nanaism/yomiyasu
src="$(mise -C "$repo_root" where github:nanaism/yomiyasu)"
if [[ ! -f "${src}/SKILL.md" ]]; then
  echo "Error: SKILL.md not found in ${src}" >&2
  exit 1
fi

skills_dir="${repo_root}/home/.agents/skills"
dest="${skills_dir}/yomiyasu"

mkdir -p "$skills_dir"

# home/ 外かつ同一ファイルシステム上に一時展開し、既存を退避してから差し替える
staging="$(mktemp -d "${common}/skills-staging.XXXXXX")"
backup=""
cleanup() {
  rm -rf "$staging"
  if [[ -n "$backup" && -e "$backup" ]]; then
    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
      mv "$backup" "$dest"
    else
      rm -rf "$backup"
    fi
  fi
}
trap cleanup EXIT

cp -R "${src}/." "${staging}/"

if [[ -e "$dest" || -L "$dest" ]]; then
  backup="${common}/skills-backup.$$"
  rm -rf "$backup"
  mv "$dest" "$backup"
fi

mv "$staging" "$dest"
if [[ -n "$backup" ]]; then
  rm -rf "$backup"
  backup=""
fi

echo "- 🧩 yomiyasu -> ${dest}"
