#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo -e "🦄 Initializing Cloning repositories... \n"

# repo 一覧の正本は infra の GitHub Stack (stacks/github/main.tf の locals.repositories)
INFRA_REPO="nozomiishii/infra"

# GitHub Stack 管理外の repo (/archive skill が退避先として使う)
extra_repos=(
  nozomiishii/archives
)

CODE_DIR="$HOME/Code"

clone_repo() {
  local repo="$1"
  if [ ! -d "$CODE_DIR/$repo" ]; then
    echo "🦄 $repo"
    git clone "git@github.com:$repo.git" "$CODE_DIR/$repo"
  fi
}

mkdir -p "$CODE_DIR"

for cmd in hcl2json jq; do
  if ! command -v "$cmd" > /dev/null; then
    echo "🚨 $cmd not found. Run: brew install $cmd" >&2
    exit 1
  fi
done

clone_repo "$INFRA_REPO"

owner="${INFRA_REPO%%/*}"
while IFS= read -r name; do
  clone_repo "$owner/$name"
done < <(hcl2json "$CODE_DIR/$INFRA_REPO/stacks/github/main.tf" | jq -r '.locals[0].repositories | keys[]')

for repo in "${extra_repos[@]}"; do
  clone_repo "$repo"
done

echo -e "🎉 Cloning repositories is complete \n\n"
