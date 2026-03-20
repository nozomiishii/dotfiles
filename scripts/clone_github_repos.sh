#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

echo -e "🦄 Initializing Cloning repositories... \n"

repos=(
  nozomiishii/dev
  nozomiishii/nozomiishii
  nozomiishii/configs
  nozomiishii/renovate
  nozomiishii/archives
  nozomiishii/workspaces
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
