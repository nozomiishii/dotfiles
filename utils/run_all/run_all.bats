#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
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

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "echo 'Hello, World!'" ]
  [[ "${lines[1]}" =~ "test_directory/test1.sh" ]]
  [ "${lines[2]}" = "echo 'Goodbye, World!'" ]
  [[ "${lines[3]}" =~ "test_directory/test2.sh" ]]
  [[ "${lines[4]}" =~ "Great job! All 2 files processed successfully." ]]
  [ "${#lines[@]}" -eq 5 ]
}

@test "Check run_all processes no files when all are ignored" {
  target_patterns=(
    "**.sh"
  )

  ignore_patterns=(
    "**"
  )
  run run_all --tool "cat" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"

  [ "$status" -eq 0 ]
  [[ "${lines[0]}" =~ "Great job! All 0 files processed successfully." ]]
  [ "${#lines[@]}" -eq 1 ]
}

@test "Check run_all processes only specified files" {
  target_patterns=(
    "test_directory/test1.sh"
  )

  ignore_patterns=(
    "test_directory/submodules/**"
  )
  run run_all --tool "cat" --target "${target_patterns[*]}" --ignore "${ignore_patterns[*]}"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "echo 'Hello, World!'" ]
  [[ "${lines[1]}" =~ "test_directory/test1.sh" ]]
  [[ "${lines[2]}" =~ "Great job! All 1 files processed successfully." ]]
  [ "${#lines[@]}" -eq 3 ]
}
