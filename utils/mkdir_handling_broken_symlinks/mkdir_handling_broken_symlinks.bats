#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  load "$DIR/../../submodules/bats-support/load"
  load "$DIR/../../submodules/bats-assert/load"

  BASENAME="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$DIR/$BASENAME.sh"

  # # Set up test directories and files
  # mkdir -p test_source/dir1
  # echo "file1" > test_source/dir1/file1

  # mkdir -p test_target
}

# Test successful directory creation
@test "mkdir_handling_broken_symlinks: create a new directory" {
  temp_dir=$(mktemp -d)
  target_path="${temp_dir}/test_dir"

  run mkdir_handling_broken_symlinks "${target_path}"

  echo "$output"
  assert [ -d "${target_path}" ]
  rm -r "${temp_dir}"
}

# Test successful directory creation after removing a broken symlink
@test "mkdir_handling_broken_symlinks: remove broken symlink and create a new directory" {
  temp_dir=$(mktemp -d)
  target_path="${temp_dir}/test_dir"
  broken_symlink="${temp_dir}/broken_symlink"

  ln -s "${target_path}" "${broken_symlink}"
  mv "${broken_symlink}" "${temp_dir}/broken_symlink_new"

  run mkdir_handling_broken_symlinks "${broken_symlink}"

  echo "$output"
  assert [ -d "${broken_symlink}" ]
  rm -r "${temp_dir}"
}

# Test unsuccessful directory creation
@test "mkdir_handling_broken_symlinks: fail to create directory" {
  temp_file=$(mktemp)
  target_path="${temp_file}/invalid_dir"

  run mkdir_handling_broken_symlinks "${target_path}"

  echo "$output"
  assert_failure
  assert_line --index 2 --partial "Failed to create directory, trying to remove broken symlink and recreate the directory"
  assert_line --index 6 --partial "Warning: Failed to create directory after removing broken symlink"
}
