#!/usr/bin/env bash
set -euo pipefail

count=$(jq -e '.skills | objects | length' skills-lock.json)
if (( count > 0 )); then
  skills install --frozen-lockfile --agent codex
fi

names=$(skills list --json --agent codex | jq -r --arg root "$(pwd -P)/.agents/skills" --argjson count "$count" '
  [.[] | select(.status == "tracked") | .path | select(startswith($root + "/")) | split("/")[-1]]
  | if length == $count then .[] else error("Some locked skills were not restored") end')

cd home/.agents/skills
cache=../../../.agents/skills
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  [[ "$(readlink "./$name")" == "$cache/$name" ]] && continue
  if [[ -d "./$name" ]]; then
    echo "Skill already exists: $name" >&2
    exit 1
  fi
  ln -s "$cache/$name" "./$name"
done <<< "$names"

for link in *; do
  [[ -L "$link" && "$(readlink "./$link")" == "$cache/$link" ]] || continue
  if ! grep -Fxq -- "$link" <<< "$names"; then
    rm -rf -- "${cache:?}/$link"
    rm -- "./$link"
  fi
done
