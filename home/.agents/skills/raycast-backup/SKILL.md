---
name: raycast-backup
description: >-
  Raycast の設定をエクスポートして dotfiles のバックアップを更新する PR を作る。
  ユーザーが「Raycast のバックアップを取って」「Raycast 設定を保存・退避したい」
  「rbk をやって」と言ったときに使用する。
---

# /raycast-backup

エクスポートから PR 作成までは [raycast_backup.sh](../../../.config/raycast/scripts/raycast_backup.sh) が正本。手順を再発明せず、このスクリプトを 1 回実行する。過去に skill → CLI 化 → skill 復帰の経緯があり ([dotfiles#999](https://github.com/nozomiishii/dotfiles/pull/999), [#1004](https://github.com/nozomiishii/dotfiles/pull/1004), [#1010](https://github.com/nozomiishii/dotfiles/pull/1010))、alias `rbk` とこの skill は同じスクリプトを共有する。

## 前提

- ローカルの macOS セッション専用。cloud セッションでは実行できないことを伝えて停止する
- Raycast が起動している (`pgrep -x Raycast`)。export の passphrase は Raycast に保存済みでプロンプトは出ない
- `gh auth status` が通る

## 実行

エクスポート中の約 10 秒、キーボードとマウスが自動操作に使われる。実行の直前に、画面を数秒自動操作するので手を離して待ってほしいと一言伝えてから実行する。追加の承認待ちは不要。

スクリプトは osascript で System Events を操作するため、ホストの sandbox 内では動かない。

- Claude Code: Bash を `dangerouslyDisableSandbox: true` で実行する
- Codex: sandbox 外での実行 (escalated permissions) の承認を得て実行する

```bash
"$HOME/.config/raycast/scripts/raycast_backup.sh"
```

## 実行後

- `PR: <url>` が出たら URL をリンクとして提示する。ブラウザは開かない (スクリプトが TTY 判定で抑制する)
- PR の diff が `home/.config/raycast/backup/Raycast.rayconfig` 1 ファイルだけであることを確認する
- 「バックアップ対象に変更なし。」で終わったらその旨を伝えて終わる。export は暗号化のため、設定が同じでもバイト差分が出て PR ができるのが通常

## 失敗時

- osascript の error 1002 は実行元アプリに Accessibility 権限がないのが原因。System Settings > Privacy & Security > Accessibility で実行元 (Claude Code / ターミナル) への付与をユーザーに依頼して停止する
- `no new .rayconfig produced` は保存ダイアログ操作の delay 不足が疑い。再実行は 1 回まで。それでも失敗したらターミナルでの `rbk` 実行を提案して停止する
