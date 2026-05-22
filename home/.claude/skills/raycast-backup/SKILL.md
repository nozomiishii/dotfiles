---
name: raycast-backup
description: Raycast 設定を1発でバックアップする。手動 export を deeplink + AppleScript で駆動し、専用ブランチに commit して PR を作成する。ユーザーが /raycast-backup と入力したときに使用する。
---

# Raycast Backup

Raycast 設定をエクスポートして dotfiles に取り込み、専用ブランチで PR を作成するスキル。**マージはしない**（ユーザーが手動で行う）。

## 前提

- Raycast 側でこのコマンドの外部起動確認を「Always Run Command」で抑制済み。
- 実行ターミナルに Accessibility 権限がある（osascript がキーストロークを送れる）。
- Export passphrase は Raycast に保存済み（無入力で export）。

## 手順

1. **repo ルート取得**（パスをハードコードしない）:
   `REPO="$(git rev-parse --show-toplevel)"`

2. **専用ブランチ作成**（origin/main 基点。どの worktree から起動してもクリーンな単独差分にする）:

   ```sh
   git -C "$REPO" fetch origin
   git -C "$REPO" switch -c "chore/raycast-backup-$(date +%Y%m%d-%H%M%S)" origin/main
   ```

3. **export 実行**:
   `"$REPO/home/.config/raycast/scripts/raycast_backup.sh" "$REPO/home/.config/raycast/backup"`
   - 非ゼロ終了時（AppleScript 失敗）: ユーザーに「Raycast の保存ダイアログで `$REPO/home/.config/raycast/backup/` に手動で Save してください。完了したら教えてください」と案内し、`*.rayconfig` の出現を待ってから次へ。手動 Save が timestamp 名なら `Raycast.rayconfig` にリネームする。

4. **生成確認**: `home/.config/raycast/backup/Raycast.rayconfig` が存在し非空であること。

5. **コミット**（変更が無ければ中断）:
   - `git -C "$REPO" add home/.config/raycast/backup/Raycast.rayconfig`
   - `git -C "$REPO" diff --cached --quiet` で**変更が無ければ**（export 失敗 or 設定無変更）、「バックアップ対象に変更なし」と報告し、作成したブランチを後始末して**中断**（push / PR しない）。
   - 変更があれば `git -C "$REPO" commit --no-verify -m "chore: update Raycast config"`

6. **push**: `git -C "$REPO" push -u origin HEAD`

7. **PR 作成**（title は英語 Conventional・**scope なし** / body は日本語、`--body-file` 使用）:

   ```sh
   BODY_FILE=$(mktemp)
   cat > "$BODY_FILE" <<'EOF'
   ## 概要

   Raycast 設定の定期バックアップ。`home/.config/raycast/backup/Raycast.rayconfig` を更新。
   EOF
   gh pr create --title "chore: update Raycast config" --body-file "$BODY_FILE"
   ```

8. PR URL を報告。**`gh pr merge` や API でのマージは絶対にしない。**

## 注意

- Raycast メイン UI は AX 非露出のため、保存ダイアログは固定 delay のブラインドキーストロークで駆動（タイミングは環境により調整）。
- バックアップは常に固定名 `Raycast.rayconfig` に上書き正規化される。
