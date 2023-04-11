#!/usr/bin/env bats

setup() {
  DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
  # make executables in src/ visible to PATH
  load "$DIR/is_file_ignored.sh"
}

@test "returns 1 when no patterns are given" {
  local patterns=()
  run is_file_ignored "file.sh" "${patterns[@]}"
  [ "$status" -eq 1 ]
}

@test "returns 0 when file matches the exact pattern" {
  local patterns=("file.sh")
  run is_file_ignored "file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}

@test "returns 1 when file matches the whitelist pattern" {
  local patterns=("!file.sh")
  run is_file_ignored "file.sh" "${patterns[@]}"
  [ "$status" -eq 1 ]
}

@test "returns 0 when file matches one of the glob patterns" {
  local patterns=("*.sh" "*.zsh")
  run is_file_ignored "file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}

@test "returns 1 when file does not match any of the glob patterns" {
  local patterns=("*.sh" "*.zsh")
  run is_file_ignored "test.txt" "${patterns[@]}"
  [ "$status" -eq 1 ]
}

@test "returns 0 when file is inside the excluded directory" {
  local patterns=("dir/**")
  run is_file_ignored "dir/file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}

@test "returns 0 when file is inside the nested excluded directory" {
  local patterns=("dir/**")
  run is_file_ignored "dir/nested/file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}

@test "returns 0 when file matches multiple exclusion patterns" {
  local patterns=("dir/**" "dir/nested/*.sh")
  run is_file_ignored "dir/nested/file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}

@test "returns 1 when file matches multiple whitelist patterns" {
  local patterns=("!dir/nested/*.sh" "!dir/nested/file.sh")
  run is_file_ignored "dir/nested/file.sh" "${patterns[@]}"
  [ "$status" -eq 1 ]
}

@test "returns 1 when file matches both exclusion and whitelist patterns" {
  local patterns=("dir/nested/*.sh" "!dir/nested/file.sh")
  run is_file_ignored "dir/nested/file.sh" "${patterns[@]}"
  [ "$status" -eq 1 ]
}

@test "returns 0 when file matches exclusion but not whitelist patterns" {
  local patterns=("dir/*.sh" "!dir/nested/file.sh")
  run is_file_ignored "dir/file.sh" "${patterns[@]}"
  [ "$status" -eq 0 ]
}
