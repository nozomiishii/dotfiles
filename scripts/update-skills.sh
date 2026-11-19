#!/usr/bin/env bash
set -euo pipefail

stable='^v?[0-9]+\.[0-9]+\.[0-9]+$'

latest_stable_tag() {
  git ls-remote --tags --refs "$1" | cut -f2 | jq -Rrn --arg current "$2" --arg stable "$stable" '
    [inputs | ltrimstr("refs/tags/") | select(test($stable))] + [$current]
    | max_by(ltrimstr("v") | split(".") | map(tonumber))'
}

jq -r '.skills | to_entries[] | .key as $name | .value | [
  $name, .source, .sourceType, (.ref // "-"),
  (.skillPath // "SKILL.md"), (.skillName // $name), (.installMode // "symlink")
] | @tsv' skills-lock.json |
while IFS=$'\t' read -r name source source_type current skill_path upstream_name install_mode; do
  if [[ $source_type != github || ! $current =~ $stable ]]; then
    skills update --project --yes "$name"
    continue
  fi

  repo="https://github.com/$source"
  latest=$(latest_stable_tag "$repo" "$current")
  [[ $latest != "$current" ]] || continue

  args=(--skill "$upstream_name" --agent codex --yes)
  if [[ $upstream_name != "$name" ]]; then args+=(--rename "$name"); fi
  if [[ $install_mode == copy ]]; then args+=(--copy); fi
  skills add "$repo/tree/$latest/$(dirname "$skill_path")" "${args[@]}"
done
