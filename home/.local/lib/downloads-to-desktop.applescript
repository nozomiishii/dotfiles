-- ~/Downloads の中身を ~/Desktop に移動する。
-- LaunchAgent から 5 秒ごとに osascript で起動される。
-- Finder 経由で move するため TCC は Finder が解決し、bash/osascript は Full Disk Access 不要。

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
