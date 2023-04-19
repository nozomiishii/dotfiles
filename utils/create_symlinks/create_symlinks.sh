#!/bin/bash

# -C: Prevent overwriting files with output redirection
# -e: Exit the script if any command returns a non-zero status
# -u: Exit the script if an undefined variable is used
# -x: (Optional) Enable command tracing for easier debugging
set -Ceu

create_symlinks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
# Including 'shellcheck source' enables Bash IDE (language server) to perform definition peeking and jumping
# shellcheck source=../msg/msg.sh
source "$create_symlinks_dir/../msg/msg.sh"
# shellcheck source=../mkdir_handling_broken_symlinks/mkdir_handling_broken_symlinks.sh
source "$create_symlinks_dir/../mkdir_handling_broken_symlinks/mkdir_handling_broken_symlinks.sh"

# This function creates symlinks from the source directory to the target directory.
# It can be used to set up configuration files or other types of files in the desired
# target directory. It takes in three parameters:
#
# --source: The source directory where the files are located.
#           This parameter is required.
#
# --target: The target directory where the symlinks should be created.
#           This parameter is required.
#
# --ignore: (optional) A regular expression pattern for files or directories that should be
#           ignored when creating symlinks. Defaults to "^_", which ignores any
#           file or directory starting with an underscore.
#
# Example usage:
#   create_symlinks --source "/path/to/source" --target "/path/to/target"
#   create_symlinks --source "/path/to/source" --target "/path/to/target" --ignore "^_"
#
create_symlinks() {
  local source_dir
  local target_dir
  local ignore_dir

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
      --ignore)
        ignore_dir="$2"
        shift
        ;;
      *)
        msg --error "Unknown parameter passed: ${1}"
        exit 1
        ;;
    esac
    shift
  done

  # Set the default value for source_dir if not provided
  if [ -z "$source_dir" ]; then
    msg --error "--source parameter is required"
    exit 1
  fi

  # Check if target_dir is provided, otherwise exit with an error
  if [ -z "$target_dir" ]; then
    msg --error "--target parameter is required"
    exit 1
  fi

  # Set the default value for ignore_dir if not provided
  if [ -z "$ignore_dir" ]; then
    ignore_dir="^_"
  fi

  # Find all files in $create_symlinks_dir and process each one
  find "$source_dir" -type f | while read -r file; do
    # Skip if the file is the same as the source directory
    if [ "$(dirname "$file")" == "$source_dir" ]; then
      continue
    fi

    # Skip if the file matches the ignore pattern. Defaults to "^_".
    if [[ "${file#"$source_dir"/}" =~ $ignore_dir ]]; then
      msg --warning "${file#"$source_dir"/}"
      msg --warning "Skip. it matches the ignore pattern\n"
      continue
    fi

    # Remove the leading $source_dir part and the next directory from the file path
    local relative_path="${file#"$source_dir/"*/}"

    local output
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
      output=$(ln -fnsv "$file" "$target_dir")
    else
      # Get the directory part of the relative path
      local target_subdir
      target_subdir=$(dirname "$relative_path")

      mkdir_handling_broken_symlinks "${target_dir}/${target_subdir}"

      # Create a symlink in the target directory for the file
      output=$(ln -fnsv "$file" "$target_dir/$relative_path")
    fi

    local cyan='\033[36m'
    local reset='\033[0m'
    msg --check "${cyan}${file#"$source_dir"/}${reset}"
    echo -e "  ${output}\n"
  done
}
