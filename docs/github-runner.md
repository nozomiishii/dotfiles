# GitHub Actions self-hosted runner 構築ガイド

自宅 Mac mini を private repo 用の macOS self-hosted runner にする手順。
設計判断は [ADR](decisions/macOS%20CI%20は自宅%20Mac%20mini%20の%20ephemeral%20self-hosted%20runner%20で受ける.md) を参照。

## 構成

Mac mini 1 台に ephemeral runner を 2 インスタンス。担当 repo は conf で決まる。
認証は専用 GitHub App で、固有値は public な dotfiles に入れない。

| 役割 | 場所 |
| --- | --- |
| 常駐ラッパー | [home/.local/bin/github-runner.sh](../home/.local/bin/github-runner.sh) |
| LaunchAgent (KeepAlive) | [home/Library/LaunchAgents/](../home/Library/LaunchAgents/) の `local.github-runner.<instance>.plist` |
| セットアップ (`make github-runner`) | [scripts/darwin/](../scripts/darwin/) の `github_runner_{setup,key,launchd}.sh` |
| repo 名・Client ID・installation ID (git 管理外) | `~/.config/github-runner/<instance>.conf` |
| GitHub App private key | macOS Keychain |
| runner 本体 (git 管理外) | `~/actions-runner/<instance>/` |

workflow 側の `runs-on` 切り替えは対象 repo の作業で本書の範囲外。

## Phase 0: Mac mini 事前確認

- [使いたい Xcode が動く macOS](https://developer.apple.com/support/xcode/) にして Xcode をインストールする
- 自動ログインを有効化する ([Apple のガイド](https://support.apple.com/ja-jp/102316))。FileVault オフが前提。
  未ログインだと LaunchAgent が動かず Keychain も読めない
- `make always-on` でスリープを無効化する

## Phase A: GitHub App 作成

- [新規 GitHub App](https://github.com/settings/apps/new) を個人アカウントで作る。
  Webhook 無効、Repository permissions は Administration の Read and write のみ
  ([必要権限](https://docs.github.com/en/rest/authentication/permissions-required-for-github-apps))、Only on this account
- Client ID を控え、private key (`.pem`) を生成する
- 対象 repo 2 つにインストールし、[Installations 一覧](https://github.com/settings/installations)の
  Configure を開いた URL 末尾から installation ID を控える (2 repo で共通)

## Phase C: Mac mini セットアップ

- dotfiles 適用後、`make github-runner` を実行する。バイナリ配置と conf 雛形 (setup) → Keychain 登録の対話 (key) → launchd 登録 (launchd) が順に走る
- `~/.config/github-runner/*.conf` に Phase A の値を記入し、`make github-runner-launchd` で launchd に登録する
- 各 repo の Settings > Actions > Runners で Idle を確認し、
  `runs-on: [self-hosted, macOS, ARM64]` の workflow で動作確認する。ログは `/tmp/github-runner.<instance>.log`

## 運用メモ

- private repo 専用。public repo での self-hosted runner は fork PR から任意コードが実行されうるため
  [GitHub が非推奨](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)
- ラベルは `self-hosted` / `macOS` / `ARM64` が自動付与。1 検証 run の実測は約 3 分
- runner バイナリは `run.sh` 起動時に自動更新される。作り直すときは launchd を bootout して
  `~/actions-runner/<instance>/` を消し、`make github-runner` を再実行する
- 鍵のローテーションとマシン移行は、App の設定ページで private key を再生成し、
  旧鍵の Keychain item を削除して `make github-runner-key` で登録し直す。
  鍵はバックアップしない (再生成しても Client ID と installation ID は変わらない)
