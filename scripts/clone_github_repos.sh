#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo -e "🦄 Initializing Cloning repositories... \n"

# GitHub のホスト鍵を known_hosts に事前登録し、初回 SSH の対話確認 (yes) を無くす。
# 鍵は TLS で保護された GitHub API から取得する
# https://docs.github.com/en/rest/meta/meta#get-apiversion-meta-information
if ! ssh-keygen -F github.com > /dev/null 2>&1; then
  echo "🦄 Registering GitHub host keys in ~/.ssh/known_hosts"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  curl -fsSL https://api.github.com/meta | jq -r '.ssh_keys[] | "github.com \(.)"' >> "$HOME/.ssh/known_hosts"
fi

repos=(
  nozomiishii/dev
  nozomiishii/nozomiishii
  nozomiishii/configs
  nozomiishii/renovate
  nozomiishii/archives
  nozomiishii/workspaces
  nozomiishii/pm
)

CODE_DIR="$HOME/Code"
if [ ! -d "$CODE_DIR" ]; then
  echo "🦄 Creating ./Code ..."
  mkdir -p "$CODE_DIR"
fi

for repo in "${repos[@]}"; do
  if [ ! -d "$CODE_DIR"/"$repo" ]; then
    echo "🦄 $repo"
    git clone git@github.com:"$repo".git "$CODE_DIR"/"$repo"
  fi
done

echo -e "🎉 Cloning repositories is complete \n\n"
