---
status: accepted
date: 2026-08-26
---

# PR タイトルの事前検証は手元に持たず CI に任せる

## 背景と課題

PR タイトルが commitlint 設定に違反していないかを、PR を作る前に手元で弾きたかった。PreToolUse hook がその役をしていたが、hook が受け取るのはシェルに渡る前のコマンド文字列で、そこから gh の呼び出しとタイトルを正規表現で取り出す作りだった。変数渡しのタイトルは展開前なので検証できず、gh を実行しないコマンド文字列にも誤爆した。

そこで gh のコマンド単位でフックする方法を調べ、PATH シムでの実装を[クローズした PR](https://github.com/nozomiishii/dotfiles/pull/1640) まで通した。動くものができた時点で、手元にこの層を持つ意味を問い直した。

CI は違反したタイトルで落ちる必須チェックとして既に動いている。プライベート repo の CI も self-hosted の Mac mini に移して実行が無料になった。手元の層は同じ判定を二重に持つことになる。

## 検討した選択肢

- PreToolUse hook を続ける: コマンド文字列の再解析が残り、誤爆と検証漏れが直らない
- gh の PATH シムに置き換える: argv を受け取るので誤爆しない。PATH の順序とシェルの起動経路に依存する層が増え、環境ごとに壊れ方が違う
- CI だけに任せる: 手元に持ち物が無い

gh 本体にコマンド前後のフックは無い。ビルトインと同名の [alias](https://cli.github.com/manual/gh_alias_set) と extension はどちらも gh が拒否するため、差し込めるのはシェルの外側だけになる。

## 決定

手元の事前検証を持たず、CI の PR タイトル検証に任せる。gh のシムは入れず、PreToolUse hook も外す。

グローバルの hooks はこれで空になる。Claude Code の settings.json と Codex の hooks.json から登録を消し、cloud 配信の対象からも外す。

## 結果

### 良くなったこと

- 判定の持ち物が CI の 1 箇所だけになる
- PATH の順序やシェルの起動経路に依存する層を保守しなくてよい
- gh を実行しないコマンド文字列への誤爆が無くなる

### 引き受けたコスト

- タイトルの違反に気づくのが PR を作った後になる。作り直しではなく `gh pr edit` で直す

### 保留した論点

- 手元の検証をまた入れたくなったときは、[クローズした PR](https://github.com/nozomiishii/dotfiles/pull/1640) の実装が出発点になる。実測で分かった落とし穴
  - 委譲先の判定に `realpath` などの外部コマンドを使うと、PATH が痩せた環境で自分自身に exec し返して gh がハングする。bash の `-ef` なら外部コマンドが要らない
  - argv からタイトルを取り出すとき、値を取るフラグの値を飛ばさないと、値に含まれる `-t` や `--title=` を拾って正当なコマンドを止める
  - Codex はコマンドを `bash -lc` で実行する。macOS の `/etc/profile` が呼ぶ path_helper が `~/.local/bin` を Homebrew より後ろへ回すため、`.zprofile` だけでは実体の gh が先に当たる
  - cloud にはシムが届かない。配信対象と PATH の配線を setup script に足す必要がある
