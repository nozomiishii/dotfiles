#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open url - compass.com
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔗
# @raycast.packageName System

# Documentation:
# @raycast.description This script opens the url of compass.com
# @raycast.author Nozomi Ishii
# @raycast.authorURL https://github.com/nozomiishii

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

city_name="大阪"
current_date=$(date "+%Y/%m/%d")

url="https://connpass.com/search/?q=$city_name&start_from=$current_date"

open "$url"
