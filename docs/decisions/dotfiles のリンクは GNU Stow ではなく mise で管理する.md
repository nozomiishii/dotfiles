---
status: accepted
date: 2026-08-24
---

# dotfiles のリンクは GNU Stow ではなく mise で管理する

## 背景と課題

home/ を `~` にシンボリックリンクする仕事を GNU Stow に任せていた。stow はディレクトリごと 1 本のリンクに畳む。この tree folding が 2 つの問題を生んでいた。

- ディレクトリごと repo に向いたリンクになるため、外部ツールの実行時書き込みが repo の working tree に漏れる。防ぐには畳まれたくないディレクトリを symlink.sh が先回りで mkdir し続ける必要があった
- 衝突した実ファイルの吸収に `--adopt` を使うと repo 側が書き換わるため、直後の `git restore` と、home/ の未コミット変更を守る事前ガードが要った

mise 2026.8 で [dotfiles セクション](https://mise.jdx.dev/dotfiles.html)によるリンク管理が入り、ツール管理で導入済みの mise に寄せられるようになった。

## 検討した選択肢

- stow を続ける: 先回りの mkdir と `git restore` のガードが残る
- mise の `[dotfiles]` symlink-each に移す: ディレクトリは実体で作り、ファイルだけをリンクする

## 決定

mise.toml の `[dotfiles]` に home/ を symlink-each で宣言し、symlink.sh は `mise bootstrap dotfiles apply --yes --force` を呼ぶ。

repo を常に正とする方針は変えない。旧構成で `--adopt` + `git restore` が担っていた「衝突する実ファイルを repo へのリンクに置き換える」は `--force` が引き継ぐ。

stow は Brewfile から外す。

## 結果

### 良くなったこと

- tree folding が無くなり、実行時書き込みが repo に漏れない。先回りの mkdir 一覧を保守しなくてよい
- repo 側を書き換える工程が消え、home/ の未コミット変更を守るガードが不要になった
- home/ からファイルを消すと、各マシンの次の apply が宙吊りリンクを掃除する

### 引き受けたコスト

- mise 2026.8 以降が前提
- リンクの記録は各マシンの state に残り、repo からは見えない
- 移行時、stow が畳んだディレクトリリンク越しには repo の実体が「衝突する実ファイル」に見える。apply の前にそのリンクを除去する処理を symlink.sh に置いた

### 保留した論点

- LaunchAgent plist や macOS defaults など、mise bootstrap の他の宣言的機能への移行
