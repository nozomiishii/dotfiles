#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  load "$DIR/../../submodules/bats-support/load"
  load "$DIR/../../submodules/bats-assert/load"

  BASENAME="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$DIR/$BASENAME.sh"

  # Create a temporary directory and initialize a new git repository
  temp_dir=$(mktemp -d)
  cd "$temp_dir" || exit 1
  git init

  # Create test files in the repository
  echo "test1" > test1.txt
  echo "test2" > test2.txt
  echo "test3" > test3.sh
  git add .
  git commit -m "Initial commit"
}

teardown() {
  # Clean up the temporary directory after tests
  cd ..
  rm -rf "$temp_dir"
}

@test "get_target_files with no options should return all files" {
  run get_target_files

  assert_success
  assert_equal "${#lines[@]}" 3
}

@test "get_target_files with --ignore option should exclude matching files" {
  run get_target_files --ignore "*.sh"

  assert_success
  for file in "${lines[@]}"; do
    [[ $file != *.sh ]]
  done
}

@test "get_target_files with --target option should include only matching files" {
  run get_target_files --target "*.sh"

  assert_success
  for file in "${lines[@]}"; do
    [[ $file == *.sh ]]
  done
}

@test "get_target_files with both --ignore and --target options should apply both filters" {
  run get_target_files --ignore "submodules/**" --target "*.sh"

  assert_success
  for file in "${lines[@]}"; do
    [[ $file != submodules/* ]]
    [[ $file == *.sh ]]
  done
}
