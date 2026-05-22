#!/usr/bin/env bash
# Raycast 設定を export し、origin/main 基点の専用ブランチで PR を作ってブラウザで開く。
# ターミナルから実行する（alias: rcb）。
#
# 前提（初回のみ）:
#   - Raycast でこのコマンドの外部起動確認を「Always Run Command」で抑制済み。
#   - 実行ターミナルに Accessibility 権限がある（無いと osascript が error 1002）。
#   - export passphrase は Raycast に保存済み（プロンプトは出ない）。
set -Ceuo pipefail

fixed_name="Raycast.rayconfig"
deeplink="raycast://extensions/raycast/raycast/export-settings-data"
backup_rel="home/.config/raycast/backup"

# stow シンボリックリンクを辿って実体の場所を求め、main repo を特定する（パスをハードコードしない）。
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [ "${src#/}" = "$src" ] && src="$dir/$src"
done
repo_root="$(cd -P "$(dirname "$src")/../../../.." && pwd)"

# export を駆動し、生成された .rayconfig を固定名に正規化する。
run_export() {
  local backup_dir="$1"
  local marker new_file candidate
  marker="$(mktemp)"

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
    if [ -n "$candidate" ]; then new_file="$candidate"; break; fi
    sleep 0.5
  done
  rm -f "$marker"

  # marker を無視した fallback はあえて持たない（古い既存ファイルを拾って偽 OK になるため）。
  if [ -z "$new_file" ] || [ ! -s "$new_file" ]; then
    echo "ERROR: no new .rayconfig produced in $backup_dir" >&2
    return 1
  fi

  # 固定名に正規化（既存があれば上書き）。
  [ "$(basename "$new_file")" = "$fixed_name" ] || mv -f "$new_file" "$backup_dir/$fixed_name"
}

branch="chore/raycast-backup-$(date +%Y%m%d-%H%M%S)"
wt="$(mktemp -d)/wt"
pr_created=0

cleanup() {
  git -C "$repo_root" worktree remove --force "$wt" 2>/dev/null || true
  rm -rf "$(dirname "$wt")"
  # PR を作れなかった場合は空ブランチを残さない。
  [ "$pr_created" = 1 ] || git -C "$repo_root" branch -D "$branch" 2>/dev/null || true
}
trap cleanup EXIT

# main repo のチェックアウトを汚さないよう、origin/main 基点の隔離 worktree で作業する。
git -C "$repo_root" fetch origin
git -C "$repo_root" worktree add -b "$branch" "$wt" origin/main

run_export "$wt/$backup_rel"

git -C "$wt" add "$backup_rel/$fixed_name"
# 変更が無ければ（export 失敗 or 設定無変更）PR を作らず終了。
if git -C "$wt" diff --cached --quiet; then
  echo "バックアップ対象に変更なし。"
  exit 0
fi

git -C "$wt" commit -m "chore: update Raycast config"
git -C "$wt" push -u origin "$branch"

body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
## 概要

Raycast 設定の定期バックアップ。`home/.config/raycast/backup/Raycast.rayconfig` を更新。
EOF
url="$(cd "$wt" && gh pr create --base main --title "chore: update Raycast config" --body-file "$body_file")"
rm -f "$body_file"
pr_created=1

echo "PR: $url"
open "$url"
