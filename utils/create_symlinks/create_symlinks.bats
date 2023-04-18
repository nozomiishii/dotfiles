#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  load "$DIR/../../submodules/bats-support/load"
  load "$DIR/../../submodules/bats-assert/load"

  BASENAME="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$DIR/$BASENAME.sh"

  # Set up test directories and files
  mkdir -p test_source/dir1
  echo "file1" > test_source/dir1/file1

  mkdir -p test_target
}

teardown() {
  # Remove test directories and files
  rm -rf test_source
  rm -rf test_target
}

@test "create symlinks with unknown parameter" {
  run create_symlinks --unknown tmp/source_dir --source test_source --target test_target

  assert_failure
  assert_line --index 0 --partial "Unknown parameter passed: --unknown"
}

@test "Symlinks are created in the target directory" {
  run create_symlinks --source test_source --target test_target

  assert_success
  assert [ -L "test_target/file1" ]
}

@test "Symlinks are created in the nested target directory" {
  mkdir -p test_source/dir2/subdir
  echo "file3" > test_source/dir2/file2
  echo "file4" > test_source/dir2/subdir/file3

  run create_symlinks --source test_source --target test_target

  assert_success
  assert [ -L "test_target/file1" ]
  assert [ -L "test_target/file2" ]
  assert [ -L "test_target/subdir/file3" ]
}

@test "Files are ignored based on the provided ignore pattern(default)" {
  mkdir -p test_source/_dir
  touch test_source/_dir/ignore_me
  run create_symlinks --source test_source --target test_target

  assert_success
  assert [ -L "test_target/file1" ]
  assert [ ! -L "test_target/ignore_me" ]
}

@test "Files are ignored based on the provided ignore pattern(customised)" {
  mkdir -p test_source/_dir
  touch test_source/_dir/include_me
  mkdir -p test_source/@dir
  touch test_source/@dir/ignore_me
  run create_symlinks --source test_source --target test_target --ignore "^@"

  assert_success
  assert [ -L "test_target/file1" ]
  assert [ -L "test_target/include_me" ]
  assert [ ! -L "test_target/ignore_me" ]
}
