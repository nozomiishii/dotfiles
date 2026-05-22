#!/usr/bin/env bash
# Raycast 設定を export し、固定名 Raycast.rayconfig に正規化する。
#
# 前提（初回のみ）:
#   - Raycast でこのコマンドの外部起動確認を「Always Run Command」で抑制済み。
#   - 実行ターミナルに Accessibility 権限がある（無いと osascript が error 1002）。
#   - export passphrase は Raycast に保存済み（プロンプトは出ない）。
#
# Usage: raycast_backup.sh <backup_dir>
set -Ceuo pipefail

backup_dir="${1:?usage: raycast_backup.sh <backup_dir>}"
backup_dir="$(cd "$backup_dir" && pwd)"

fixed_name="Raycast.rayconfig"
deeplink="raycast://extensions/raycast/raycast/export-settings-data"

# 新しく書かれた export を検出するための基準時刻。
marker="$(mktemp)"
trap 'rm -f "$marker"' EXIT

# 保存ダイアログは AX 非露出なので、固定 delay + ブラインドキーストロークで操作する。
# delay はマシン速度で要調整。
osascript <<OSA
set targetDir to "$backup_dir"
-- Export を起動
do shell script "open '$deeplink'"
delay 1.5
tell application "System Events"
  -- Export 実行 → 保存ダイアログが開く
  key code 36
  delay 1.8
  -- Go to Folder を開く（Cmd+Shift+G）
  keystroke "g" using {command down, shift down}
  delay 1.0
  -- パスを直接タイプ（Cmd+V は効かなかった）
  keystroke targetDir
  delay 0.6
  -- パス確定して移動
  key code 36
  delay 0.8
  -- 保存
  key code 36
  delay 1.0
  -- 確認/通知を Escape で閉じる
  key code 53
end tell
OSA

# marker より新しい .rayconfig が現れるまで最大 15 秒待つ。
new_file=""
for _ in $(seq 1 30); do
  candidate="$(find "$backup_dir" -maxdepth 1 -name '*.rayconfig' -newer "$marker" -print 2>/dev/null | head -n1)"
  if [ -n "$candidate" ]; then
    new_file="$candidate"
    break
  fi
  sleep 0.5
done

# marker を無視した fallback はあえて持たない（古い既存ファイルを拾って偽 OK になるため）。
if [ -z "$new_file" ] || [ ! -s "$new_file" ]; then
  echo "ERROR: no new .rayconfig produced in $backup_dir" >&2
  exit 1
fi

# 固定名に正規化（既存があれば上書き）。
if [ "$(basename "$new_file")" != "$fixed_name" ]; then
  mv -f "$new_file" "$backup_dir/$fixed_name"
fi

echo "OK: $backup_dir/$fixed_name"
