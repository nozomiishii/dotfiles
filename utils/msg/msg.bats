#!/usr/bin/env bats

setup() {
  local dir
  dir="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  load "$dir/../../submodules/bats-support/load"
  load "$dir/../../submodules/bats-assert/load"

  local filename
  filename="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$dir/$filename.sh"
}

@test "msg function prints error message" {
  run msg "Error message" --error

  echo "$output"
  assert_success
  assert_line --index 0 --partial "ERROR: Error message"
  assert_equal "${#lines[@]}" 2
}

@test "msg function prints success message" {
  run msg "Success message" --pass

  echo "$output"
  assert_success
  assert_line --index 0 --partial "Success message"
}

@test "msg function prints warning message" {
  run msg "Warning message" --warning

  echo "$output"
  assert_success
  assert_line --index 0 --partial "Warning: Warning message"
}

@test "msg function works with reversed arguments" {
  run msg --error "Error message"

  echo "$output"
  assert_success
  assert_line --index 0 --partial "ERROR: Error message"
}

@test "msg function works with no arguments" {
  run msg "message"

  echo "$output"
  assert_success
  assert_line --index 0 --partial "message"
}
