---
status: accepted
date: 2026-08-29
---

# dotfiles のリンクは mise の task に一本化する

## 背景と課題

[dotfiles のリンクは GNU Stow ではなく mise で管理する](<dotfiles のリンクは GNU Stow ではなく mise で管理する.md>)で、リンクの実行は mise に移った。`scripts/symlink.sh` は mise を呼ぶだけのラッパーとして残った。

install.sh には順序制約がある。

- 素の Mac で `curl | bash` から走るので、その時点で mise はまだ無い
- グローバルツールを宣言する `~/.config/mise/config.toml` は home/ からリンクされるので、`mise install` はリンクより後になる
- macos.sh は home/ からリンクされる LaunchAgent plist を `launchctl bootstrap` するので、これもリンクより後になる

この知識が symlink.sh と `scripts/toolchains/mise.sh` に分かれて置かれ、どちらを読んでも全体像が分からなかった。

## 検討した選択肢

- symlink.sh を薄くして残す: 順序知識が 2 ファイルに分かれたまま
- install.sh に mise のコマンドを直書き: 実行順は読みやすいが、install.sh が script の羅列でなくなる
- mise.sh にリンクを集約: 順序制約が 1 ファイルに収まる

## 決定

`scripts/toolchains/mise.sh` が mise の導入、リンク、グローバルツールの導入を順に行う。install.sh では macos.sh より前に置く。

リンク操作の定義は `mise.toml` の `[tasks.link]` 1 箇所とし、mise.sh からもこの task を通す。同じ操作が 2 箇所に別スペルで残ると、片方だけ直す事故が起きる。

`[tasks.link]` は `git rev-parse --git-common-dir` で本体の checkout を割り出し、そこの config を指して apply する。worktree の home/ を `~` の正にすると、worktree を消した時点で全リンクが宙吊りになる。

`dotfiles.root` では解決できない。この設定はソースを省略したときの基準ディレクトリで、`source = "home"` と明示している構成では無視される。`source` にテンプレートも書けない。

`[tasks.toolchains]` からは mise.sh を外し、代わりに `mise install` を直接並べる。mise.sh を残すとツール更新のつもりで叩いた `mise run toolchains` が毎回 `--force` でリンクを張り直し、`~` の実ファイルを確認なしに上書きする。mise 本体の更新は `~/.config/mise/config.toml` の `auto_update` が担う。

`mise install` にはリトライを付ける。install.sh でこの後に macos.sh が控えるため、ネットワークの一時的な失敗で macos.sh まで巻き添えにしない。

## 結果

### 良くなったこと

- 順序制約が mise.sh 1 ファイルに収まった
- リンク操作の定義が `[tasks.link]` だけになった
- worktree から叩いても `~` は本体を指す

### 引き受けたコスト

- mise が入っていないマシンで、リンクだけを復旧する軽量な経路が消えた。代わりに `bash scripts/toolchains/mise.sh` を走らせる
- `mise run link` は task なので、mise の `auto_install` が repo の node と pnpm を先に入れる。オフラインでは、この task を呼ぶ lefthook の post-merge symlink job が落ちる
- worktree で編集中の home/ は `~` に反映されない。試すには merge するか、`mise -C <worktree> bootstrap dotfiles apply` を直接叩く

### 保留した論点

- `~/.local/state/mise/dotfiles` のリンク台帳が壊れた時の復旧手順は残していない。台帳を消して `mise run link` を叩き直すと通るが、管理外になった古いリンクは掃除されずに `~` に残る
