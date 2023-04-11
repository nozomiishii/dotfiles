#!/bin/bash

is_file_ignored() {
  local file="$1"
  shift
  local patterns=("$@")
  local matched=1

  for pattern in "${patterns[@]}"; do
    if [[ $pattern == !* && $file == "${pattern#!}" ]]; then
      matched=1
      break
    fi

    # shellcheck disable=SC2053
    if [[ $file == $pattern ]]; then
      matched=0
    fi
  done

  return "$matched"
}
