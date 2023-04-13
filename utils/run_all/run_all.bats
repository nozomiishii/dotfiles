#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  load "$DIR/../../submodules/bats-support/load"
  load "$DIR/../../submodules/bats-assert/load"

  BASENAME="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$DIR/$BASENAME.sh"

  # Create temporary test files
  mkdir -p test_directory/submodules
  echo "echo 'Hello, World!'" > "test_directory/test1.sh"
  echo "echo 'Goodbye, World!'" > "test_directory/test2.sh"
}

teardown() {
  # Remove the temporary test directory
  rm -rf test_directory
}

@test "Check run_all processes the correct files" {
  target_patterns=(
    "test_directory/test1.sh"
    "test_directory/test2.sh"
  )

  ignore_patterns=(
    "test_directory/submodules/**"
  )
  run run_all --tool "cat" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"

  assert_success
  assert_line --index 0 "echo 'Hello, World!'"
  assert_line --index 1 --partial "test_directory/test1.sh"
  assert_line --index 2 "echo 'Goodbye, World!'"
  assert_line --index 3 --partial "test_directory/test2.sh"
  assert_line --index 4 --partial "All 2 files processed successfully."
  assert_equal "${#lines[@]}" 5
}

@test "Check run_all processes no files when all are ignored" {
  target_patterns=(
    "**.sh"
  )

  ignore_patterns=(
    "**"
  )
  run run_all --tool "cat" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"

  assert_success
  assert_line --index 0 --partial "All 0 files processed successfully."
  assert_equal "${#lines[@]}" 1
}

@test "Check run_all processes only specified files" {
  target_patterns=(
    "test_directory/test1.sh"
  )

  ignore_patterns=(
    "test_directory/submodules/**"
  )
  run run_all --tool "cat" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"

  assert_success
  assert_line --index 0 "echo 'Hello, World!'"
  assert_line --index 1 --partial "test_directory/test1.sh"
  assert_equal "${#lines[@]}" 3

}
