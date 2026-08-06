# macOS CI は自宅 Mac mini の ephemeral self-hosted runner で受ける

Status: accepted
Date: 2026-08-07

## Context — 判断を迫られた状況

private repo の macOS CI が GitHub-hosted の macOS runner で Actions の無料枠を Linux の 10 倍速で消費していた。常時稼働できる Mac mini (M4) が自宅にある。設計の議論は [dotfiles#1491](https://github.com/nozomiishii/dotfiles/pull/1491)。

## Decision — 決めたこと

- macOS CI は Mac mini の self-hosted runner で受ける。個人アカウントは org runner を使えないため repo 単位で登録する
- ephemeral + launchd 常駐。1 ジョブごとに登録し直して環境汚染を防ぎ、再起動後も自動復帰する
- 認証は PAT でなく専用 GitHub App。権限を Administration の Read and write に絞り、対象 repo にだけインストールする
- dotfiles は public のため、repo 名・Client ID・installation ID は `~/.config/github-runner/`、private key は macOS Keychain に置く。インスタンス名も repo 名を出さない `runner1` / `runner2` にする

## Consequences — 決定がもたらすもの

- macOS CI が無料枠を消費しなくなる。1 検証 run の実測は約 3 分
- Mac mini の常時稼働 (自動ログイン・スリープ無効・FileVault オフ) が CI の前提になる
- GitHub App の private key の管理が増える
- セットアップ手順は [github-runner.md](../github-runner.md) に切り出す
