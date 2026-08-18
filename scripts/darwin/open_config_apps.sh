#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

if [ "${CI:-false}" = "true" ]; then
  echo "Running in CI environment - skipping app opening"
  exit 0
fi

echo "👨🏻‍🚀 Open the apps that needs to be configured"
open -b com.apple.systempreferences
open "/Applications/Google Drive.app"
open "/Applications/Google Chrome.app"
open "/Applications/Raycast.app"
open "/Applications/1Password.app"
open /users
open https://github.com/nozomiishii/dotfiles
echo "👨🏻‍🚀 Please refer to github to set up the launched application"
