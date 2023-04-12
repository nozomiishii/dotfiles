#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" > /dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  load "$DIR/remove_temp_files.sh"
}

# Test case: remove_temp_files should remove existing files
@test "remove_temp_files removes existing files" {
  # Create temporary files for testing
  temp_file_1="$(mktemp)"
  temp_file_2="$(mktemp)"

  # Call the remove_temp_files function with the temporary file paths
  run remove_temp_files "$temp_file_1" "$temp_file_2"

  # Assert that the temporary files were removed
  [ ! -f "$temp_file_1" ]
  [ ! -f "$temp_file_2" ]
}

# Test case: remove_temp_files should not fail if files do not exist
@test "remove_temp_files does not fail if files do not exist" {
  # Create non-existing file paths
  non_existing_file_1="/tmp/non_existing_file_1"
  non_existing_file_2="/tmp/non_existing_file_2"

  # Call the remove_temp_files function with the non-existing file paths
  run remove_temp_files "$non_existing_file_1" "$non_existing_file_2"

  # Assert that the function did not fail
  [ "$status" -eq 0 ]
}

# Test case: remove_temp_files should not remove directories
@test "remove_temp_files does not remove directories" {
  # Create a temporary directory for testing
  temp_directory="$(mktemp -d)"

  # Call the remove_temp_files function with the temporary directory path
  run remove_temp_files "$temp_directory"

  # Assert that the temporary directory was not removed
  [ -d "$temp_directory" ]

  # Clean up the temporary directory
  rmdir "$temp_directory"
}
