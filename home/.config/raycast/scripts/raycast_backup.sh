#!/usr/bin/env bash
# Trigger Raycast "Export Settings & Data" via deeplink, drive the macOS save
# dialog with AppleScript, then normalize the result to a fixed filename.
#
# Prerequisites (one-time):
#   - The external-trigger confirmation for this command is suppressed in
#     Raycast via "Always Run Command".
#   - The terminal app running this script has Accessibility permission so
#     osascript can send keystrokes (else: error 1002).
#   - The Raycast export passphrase is stored in Raycast (no prompt appears).
#
# Usage: raycast_backup.sh <backup_dir>
#
# -C noclobber / -e errexit / -u nounset / -o pipefail
set -Ceuo pipefail

backup_dir="${1:?usage: raycast_backup.sh <backup_dir>}"
backup_dir="$(cd "$backup_dir" && pwd)"

fixed_name="Raycast.rayconfig"
deeplink="raycast://extensions/raycast/raycast/export-settings-data"

# Reference time to detect the freshly written export.
marker="$(mktemp)"
trap 'rm -f "$marker"' EXIT

# Raycast's main UI (and the out-of-process save panel) is not reliably exposed
# via the Accessibility tree, so the save dialog is driven with fixed delays +
# blind keystrokes targeting the front window (approach from arunvelsriram/dotfiles).
#
# NSSavePanel does not accept a path in its filename field, but the Go-to-Folder
# sheet (Cmd+Shift+G) is a path field -- type the POSIX path there, then Return to
# navigate. (Clipboard paste / Cmd+V did NOT land on this machine even though plain
# keys did -- Return closed the sheet -- so the path is typed directly instead.)
# Refs: Apple Community 254893349, Satimage file_paths.
#
# Delays may need tuning per machine.
osascript <<OSA
set targetDir to "$backup_dir"
do shell script "open '$deeplink'"
delay 1.5 -- wait for the Export form
tell application "System Events"
  key code 36 -- Export (Return) -> opens the save dialog
  delay 1.8 -- wait for the save dialog
  keystroke "g" using {command down, shift down} -- Go to Folder
  delay 1.0 -- wait for the Go-to-Folder sheet (field opens empty + focused)
  keystroke targetDir -- type the POSIX path into the Go-to field
  delay 0.6
  key code 36 -- confirm Go to Folder (navigate)
  delay 0.8
  key code 36 -- Save
  delay 1.0
  key code 53 -- Escape (dismiss confirmation/notification)
end tell
OSA

# Wait (max ~15s) for a .rayconfig newer than the marker to appear.
new_file=""
for _ in $(seq 1 30); do
  candidate="$(find "$backup_dir" -maxdepth 1 -name '*.rayconfig' -newer "$marker" -print 2>/dev/null | head -n1)"
  if [ -n "$candidate" ]; then
    new_file="$candidate"
    break
  fi
  sleep 0.5
done

# No marker-less fallback on purpose: picking the newest .rayconfig regardless of
# the marker would select the pre-existing committed Raycast.rayconfig and report
# a false "OK" when the export silently failed.
if [ -z "$new_file" ] || [ ! -s "$new_file" ]; then
  echo "ERROR: no new .rayconfig produced in $backup_dir" >&2
  exit 1
fi

# Normalize to the fixed filename (overwrite any previous one).
if [ "$(basename "$new_file")" != "$fixed_name" ]; then
  mv -f "$new_file" "$backup_dir/$fixed_name"
fi

echo "OK: $backup_dir/$fixed_name"
