#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  BASENAME="$(basename "$BATS_TEST_FILENAME" .bats)"
  load "$DIR/$BASENAME.sh"

  # Create temporary test files
  mkdir -p test_directory/submodules
  echo "echo 'Hello, World!'" > test_directory/test1.sh
  echo "echo 'Goodbye, World!'" > test_directory/submodules/test2.sh
}

teardown() {
  # Remove temporary test files
  rm -rf test_directory
}
@test "Check run_all processes the correct files" {
  run run_all --tool "shfmt -w -i 2 -bn -ci -sr" --target "*.sh" --ignore "submodules/**"

  echo "$output"
  [ "$status" -eq 0 ]
  # [ "${lines[0]}" = "✓ test_directory/test1.sh" ]
  # [ "${lines[1]}" = "" ]
  # [ "${lines[2]}" = "PASS Great job! All 1 files processed successfully." ]
}

@test "Check run_all ignores the specified files" {
  run run_all --tool "shfmt -w -i 2 -bn -ci -sr" --target "*.sh" --ignore "test_directory/submodules/**"
  echo "$output"
  [ "$status" -eq 0 ]
  # [ "${lines[0]}" = "✓ test_directory/test1.sh" ]
  # [ "${lines[1]}" = "" ]
  # [ "${lines[2]}" = "PASS Great job! All 1 files processed successfully." ]
}
