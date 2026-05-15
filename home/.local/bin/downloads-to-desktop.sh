#!/usr/bin/env bash
# ~/Downloads にファイルが追加されたら ~/Desktop へ移動する。
# fswatch でイベント検知 → osascript で AppleScript を起動 → Finder が move を実行 (TCC は Finder が解決)。
#
# 注: 実 move は Finder が行うため、bash / fswatch / osascript に Full Disk Access は不要。

set -uo pipefail

SRC="$HOME/Downloads"
APPLESCRIPT="$HOME/.local/lib/downloads-to-desktop.applescript"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

if ! command -v fswatch >/dev/null 2>&1; then
  log "fswatch not found in PATH; install via 'brew install fswatch'"
  exit 127
fi

log "watching $SRC"

# -0: NULL 区切り / Created・MovedTo・Renamed を監視
exec fswatch -0 \
  --event Created \
  --event MovedTo \
  --event Renamed \
  "$SRC" |
  while IFS= read -r -d '' _; do
    /usr/bin/osascript "$APPLESCRIPT"
  done
