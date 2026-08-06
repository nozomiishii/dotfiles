# GitHub Actions self-hosted runner 構築ガイド

自宅 Mac mini を private repo 用の macOS self-hosted runner にする手順。
GitHub-hosted の macOS runner は無料枠を 10 倍速で消費するため、
macOS CI は自宅の Mac mini で受ける。

## 構成

- runner は repo 単位で登録する (個人アカウントのため org runner は使えない)。
  Mac mini 1 台に `runner1` / `runner2` の 2 インスタンスを置き、それぞれ別の repo を受ける
- 認証は専用の GitHub App (PAT は使わない)。
  private key は macOS Keychain、repo 名・client ID・installation ID は
  `~/.config/github-runner/<instance>.conf` に置き、public な dotfiles には入れない
- ephemeral runner: 1 ジョブ処理するたびに GitHub 側が登録解除し、
  [github-runner.sh](../home/.local/bin/github-runner.sh) が再登録する。
  クリーンな環境がジョブごとに保証される
- launchd (`local.github-runner.<instance>.plist`) で常駐し、再起動後も自動復帰する

| 役割 | ファイル |
| --- | --- |
| 常駐ラッパー (登録 → 実行の無限ループ) | [home/.local/bin/github-runner.sh](../home/.local/bin/github-runner.sh) |
| LaunchAgent | [home/Library/LaunchAgents/local.github-runner.runner1.plist](../home/Library/LaunchAgents/local.github-runner.runner1.plist) ほか |
| セットアップ (`make github-runner`) | [scripts/darwin/github_runner.sh](../scripts/darwin/github_runner.sh) |
| インスタンス設定 (git 管理外) | `~/.config/github-runner/<instance>.conf` |
| runner 本体 (git 管理外) | `~/actions-runner/<instance>/` |

Phase B (workflow 側で `runs-on` を切り替える変更) は対象 repo 側の作業のため本書の範囲外。

## Phase 0: Mac mini 事前確認

1. **macOS バージョン**: 使いたい Xcode が動く macOS か確認する。
   Xcode 26.0〜26.3 は macOS Sequoia 15.6 以降、Xcode 26.4.1 以降は macOS Tahoe 26.2 以降が必要
   ([Xcode サポートページ](https://developer.apple.com/support/xcode/))
2. **Xcode 26 インストール**: App Store か [Apple Developer](https://developer.apple.com/download/applications/) から。
   起動して追加コンポーネントのインストールまで済ませ、`xcodebuild -version` で確認する
3. **自動ログイン有効化**: システム設定 > ユーザとグループ > 自動ログイン
   ([Apple のガイド](https://support.apple.com/ja-jp/102316))。
   FileVault がオンだと自動ログインは使えないため、FileVault はオフが前提。
   ログインしていないと LaunchAgent が起動せず、Keychain も読めない
4. **スリープ無効**:

   ```bash
   make always-on
   ```

## Phase A: GitHub App 作成

registration token の取得には Administration 権限が要るため、
PAT ではなく最小権限の専用 GitHub App を作る
([必要権限のリファレンス](https://docs.github.com/en/rest/authentication/permissions-required-for-github-apps))。

1. [新規 GitHub App 作成](https://github.com/settings/apps/new) (個人アカウント)
   - GitHub App name: `<owner>-actions-runner` など
   - Homepage URL: この dotfiles の URL で可
   - Webhook: **Active のチェックを外す**
   - Repository permissions: **Administration: Read and write** のみ
   - Where can this GitHub App be installed?: **Only on this account**
2. 作成後の App 設定ページで **Client ID** を控える
3. 同ページ下部の Private keys で **Generate a private key** → `.pem` がダウンロードされる。
   Phase C で Keychain に登録したら削除する
4. 左メニューの Install App から、runner を使う対象 repo (2 つ) にインストールする
5. **Installation ID** を控える: [Installations 一覧](https://github.com/settings/installations)で
   該当 App の Configure を開いたときの URL 末尾の数字 (`settings/installations/<ID>`)。
   個人アカウントへのインストールは 1 つなので、2 repo で共通

## Phase C: Mac mini セットアップ

1. dotfiles を適用する (未適用なら [README](../README.md) の手順で `install.sh`、適用済みなら `make link`)
2. セットアップスクリプトを実行する:

   ```bash
   make github-runner
   ```

   runner バイナリの配置、conf 雛形の作成、private key の Keychain 登録 (対話) が走る
3. `~/.config/github-runner/runner1.conf` / `runner2.conf` に Phase A で控えた値を記入する
4. もう一度 `make github-runner` を実行すると、conf 記入済みのインスタンスが launchd に登録される
5. 各 repo の Settings > Actions > Runners で runner が **Idle** 表示になることを確認する
6. 動作確認: 対象 repo で `runs-on: [self-hosted, macOS, ARM64]` の workflow を実行する。
   ログは `/tmp/github-runner.<instance>.log`

## 運用メモ

- **private repo 専用**。public repo での self-hosted runner は
  fork PR から任意コードが実行されうるため
  [GitHub が非推奨](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)。
  対象 repo を public に切り替えるときは runner を外す
- ラベルは `self-hosted` / `macOS` / `ARM64` が自動付与される
- 1 検証 run の実測は約 3 分
- runner バイナリは `run.sh` 起動時に自動更新される。
  作り直したいときは `launchctl bootout gui/$UID ~/Library/LaunchAgents/local.github-runner.<instance>.plist`
  で止めて `~/actions-runner/<instance>/` を消し、`make github-runner` を再実行する
