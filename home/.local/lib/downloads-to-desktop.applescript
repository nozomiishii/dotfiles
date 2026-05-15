-- ~/Downloads の中身を ~/Desktop に移動する。
-- LaunchAgent の WatchPaths でファイル変更を検知 → osascript でこのスクリプトを起動。
-- Finder 経由で move するため TCC は Finder が解決し、Full Disk Access は不要。

tell application "Finder"
  set src to folder "Downloads" of (path to home folder)
  set dst to folder "Desktop" of (path to home folder)
  repeat with anItem in (get items of src)
    set itemName to name of anItem
    set itemExt to name extension of anItem
    -- ドット始まり (.DS_Store 等) と、各ブラウザのダウンロード途中ファイルを除外
    if itemName does not start with "." ¬
      and itemExt is not in {"crdownload", "download", "part"} then
      try
        move anItem to dst with replacing
      end try
    end if
  end repeat
end tell
