#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "🧝🏻‍♀️ Starting Configs setup...\n\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

create_symlinks() {
  local green='\033[0;32m'
  local red="\033[1;31m"
  local reset='\033[0m'

  local source_dir
  local target_dir

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --source)
        source_dir="$2"
        shift
        ;;
      --target)
        target_dir="$2"
        shift
        ;;
      *)
        echo -e "${red}ERROR: Unknown parameter passed: ${1}${reset}\n\n"
        exit 1
        ;;
    esac
    shift
  done

  # Set the default value for source_dir if not provided
  if [ -z "$source_dir" ]; then
    source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
  fi

  # Check if target_dir is provided, otherwise exit with an error
  if [ -z "$target_dir" ]; then
    echo -e "${red}ERROR: --target parameter is required${reset}\n\n"
    exit 1
  fi

  # Find all files in $SCRIPT_DIR and process each one
  find "$source_dir" -type f | while read -r file; do
    # Skip if the file is the same as the source directory
    if [ "$(dirname "$file")" == "$source_dir" ]; then
      continue
    fi

    # Remove the leading $source_dir part and the next directory from the file path
    local relative_path="${file#"$source_dir/"*/}"

    if [ "$relative_path" == "." ]; then
      # Create a symlink in the target directory for the file
      #
      # ln [options] source_file [target_file]
      #
      #  -f    If the target file already exists, then unlink it so that the link may occur.  (The
      #        -f option overrides any previous -i and -w options.)
      #  -h    If the target_file or target_dir is a symbolic link, do not follow it.  This is most
      #        useful with the -f option, to replace a symlink which may point to a directory.
      #  -n    Same as -h, for compatibility with other ln implementations.
      #  -s    Create a symbolic link.
      #  -v    Cause ln to be verbose, showing files as they are processed.
      ln -fnsv "$file" "$target_dir"
    else
      local target_subdir
      # Get the directory part of the relative path
      target_subdir=$(dirname "$relative_path")
      # Create the target directory in $HOME if it doesn't exist
      mkdir -p "$target_dir/$target_subdir"

      # Create a symlink in the target directory for the file
      ln -fnsv "$file" "$target_dir/$relative_path"
    fi

    echo -e "${green}✓ ${file#"$source_dir"/}${reset}"
  done
}

create_symlinks --source "$SCRIPT_DIR" --target "$HOME"

echo -e "\n\n${GREEN}🧝🏻‍♀️ Setup Configs is complete 🎉${RESET}\n\n"
