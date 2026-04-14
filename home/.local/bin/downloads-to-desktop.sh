#!/usr/bin/env bash
#
# ~/Downloads に入ったファイルを ~/Desktop へ自動移動する。
# AirDrop の保存先を変更できない macOS の制約を回避する用途。
# fswatch でイベント監視し、ダウンロード途中の一時ファイルは除外する。

set -uo pipefail

SRC="$HOME/Downloads"
DST="$HOME/Desktop"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

# ダウンロード途中とみなす拡張子・パターン
is_temp_file() {
  local name="$1"
  case "$name" in
    .*) return 0 ;;          # ドット始まり（.DS_Store 等）
    *.crdownload) return 0 ;; # Chromium
    *.download) return 0 ;;   # Safari
    *.part) return 0 ;;       # Firefox
    *~) return 0 ;;           # エディタ等のバックアップ
    *) return 1 ;;
  esac
}

# サイズが安定するまで待つ（書き込み中のファイル対策）
wait_until_stable() {
  local path="$1"
  local prev=-1 curr=0 tries=0
  while [ "$prev" != "$curr" ] && [ "$tries" -lt 20 ]; do
    prev="$curr"
    sleep 0.5
    if [ ! -e "$path" ]; then
      return 1
    fi
    curr=$(stat -f '%z' "$path" 2>/dev/null || echo 0)
    tries=$((tries + 1))
  done
  return 0
}

# 同名衝突時に " (2)"," (3)" を付ける
resolve_destination() {
  local base="$1"
  local target="$DST/$base"
  if [ ! -e "$target" ]; then
    printf '%s\n' "$target"
    return
  fi

  local name="${base%.*}"
  local ext=""
  if [ "$name" != "$base" ]; then
    ext=".${base##*.}"
  fi

  local i=2
  while [ -e "$DST/${name} (${i})${ext}" ]; do
    i=$((i + 1))
  done
  printf '%s\n' "$DST/${name} (${i})${ext}"
}

handle_path() {
  local path="$1"

  # SRC 直下のファイルのみ対象（サブディレクトリ配下のイベントは無視）
  local parent
  parent="$(dirname "$path")"
  [ "$parent" = "$SRC" ] || return 0

  [ -e "$path" ] || return 0

  local name
  name="$(basename "$path")"

  if is_temp_file "$name"; then
    return 0
  fi

  # ディレクトリは対象外（AirDrop 単ファイル運用）
  if [ -d "$path" ]; then
    return 0
  fi

  if ! wait_until_stable "$path"; then
    log "disappeared before stable: $path"
    return 0
  fi

  local dest
  dest="$(resolve_destination "$name")"

  if mv -- "$path" "$dest" 2>/dev/null; then
    log "moved: $path -> $dest"
  else
    log "failed to move: $path"
  fi
}

if ! command -v fswatch >/dev/null 2>&1; then
  log "fswatch not found in PATH; install via 'brew install fswatch'"
  exit 127
fi

mkdir -p "$DST"

log "watching $SRC -> $DST"

# -0: NULL 区切り / 作成・移動・リネームを監視
fswatch -0 \
  --event Created \
  --event MovedTo \
  --event Renamed \
  "$SRC" |
  while IFS= read -r -d '' path; do
    handle_path "$path"
  done
