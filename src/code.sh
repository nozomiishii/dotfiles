#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

printf "🦄 Starting Cloning repositories... \n"

CODE_DIR="$HOME/Code"
if [ ! -d "$CODE_DIR" ]; then
  echo "🦄" Creating" ./Code ..."
  mkdir -p "$CODE_DIR"
fi

repos=(
  nozomiishii/dev
  nozomiishii/nozomiishii
  nozomiishii/configs
  nozomiishii/renovate
  nozomiishii/archives
)

for repo in "${repos[@]}"; do
  if [ ! -d "$CODE_DIR"/"$repo" ]; then
    echo "🦄 $repo"
    git clone git@github.com:"$repo".git "$CODE_DIR"/"$repo"
  fi
done

printf "🎉 Cloning repositories is complete \n\n"
