#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Tampermonkey - Dashboard
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🐵
# @raycast.packageName System

# Documentation:
# @raycast.description This script opens the Tampermonkey dashboard in Google Chrome.
# @raycast.author Nozomi Ishii
# @raycast.authorURL https://github.com/nozomiishii

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

# Raycast のクイックリンクは Open With を無視して -a なしで open するため、chrome-extension:// を開けない
open -a "Google Chrome" "chrome-extension://dhdgffkkebhmkfjojejmpbldmpobfkfo/options.html#nav=dashboard"
