---
status: accepted
date: 2026-08-26
---

# PR タイトル検証は PreToolUse フックではなく gh シムで行う

## 背景と課題

PR タイトルを repo の commitlint 設定で検証する仕組みを、Claude Code と Codex の PreToolUse hook に置いていた。hook が受け取るのはシェルに渡る前のコマンド文字列なので、そこから gh の呼び出しとタイトルを取り出すために正規表現でシェルを再解析していた。

再解析には 3 つの実害があった。

- クォートの扱いを自前で持つ。`--template` の中の `-t` を短縮形と読み違えないための細工が要り、テストの大半がその検証に費やされた
- `--title "$TITLE"` の変数渡しを検証できない。展開前の文字列には値が無いため素通りする
- gh を実行しないコマンドにも誤爆する。`gh pr create --title "..."` という文字列を含むだけのスクリプトやドキュメント編集がブロックされた

同じ実体を Claude Code の settings.json と Codex の hooks.json に二重登録する必要もあり、片方だけ直したまま放置された。

gh 本体にコマンド前後のフックは無く、シェルの外側でラップする以外に差し込み口が無い。

## 検討した選択肢

### 検証をどこで行うか

| 選択肢 | 評価 |
| --- | --- |
| hook の正規表現をシェルのトークナイザに置き換える | 誤爆は減るが、変数展開後の値は得られない。二重登録も残る |
| gh の alias / extension でコマンドを差し替える | ビルトインと同名はどちらも gh 本体が拒否する (`already a gh command or extension` / `matches the name of a built-in command or alias`) |
| PATH シムで gh をラップする | シェルが展開した argv を受け取るので解析が要らない。エージェント・手打ち・スクリプトの全経路に効く |

### シムの置き場

| 選択肢 | 評価 |
| --- | --- |
| `home/.local/bin/` | 実行ファイルの実体を置く既存の規約に乗る。cloud の配置先とパスが揃う |
| `home/.agents/shims/` | cloud 配信が `home/.agents/**` を丸ごと拾うため workflow を触らずに済む。実行ファイルの置き場としては新設 |
| `home/.local/share/shims/` | ラッパーであることが名前で分かる。PATH に載せるディレクトリが 1 つ増える |

## 決定

`home/.local/bin/gh` にシムを置き、hook は撤去する。

シムは多段に並んでも順に委譲し、最後に実体の gh へ届く。誤作動したときの急ぎの回避は `GH_SHIM_CHECKED=1` を渡す。

.zprofile では mise を有効化した後に `~/.local/bin` を前置し、mise のツールシムより先に解決させる。Codex の `bash -lc` は .zprofile を読まず、path_helper が `~/.local/bin` を Homebrew より後ろへ回すため、`.bash_profile` でも前置する。

cloud には mise が無いので、setup script が書き込めるディレクトリへシムを複製する。

判定ルールは持たず lefthook の commit-msg と同じ nozo-commitlint に流す方針は変えない。

## 結果

### 良くなったこと

- コマンド文字列の再解析が消え、クォート解析とその周辺のテストが不要になった
- 変数渡しのタイトルを検証できる。展開後の argv を受け取るため
- gh を実行しない文字列への誤爆が構造的に起きなくなった
- Claude Code と Codex の二重登録が 1 実体に集約された

### 引き受けたコスト

- `.zprofile` も `.bash_profile` も読まない裸の `zsh -c` / `bash -c` には効かない。取りこぼしは CI の PR タイトル検証が受ける
- login bash 全般で `~/.local/bin` が最優先になる。`.bash_profile` を新設した副作用で、gh 以外の同名コマンドもここが先に当たる
- 検証が届く範囲は gh の呼び方に依る。サブコマンドの前に `--repo` 以外のフラグを置いた形、alias や extension 経由、タイトルを対話で入れる形は素通りする
- `.bash_profile` を dotfiles が持つことになり、既に実体を置いている Mac では上書きされる。login bash は `.bash_profile` があると `.profile` を読まなくなる
- シムが壊れて gh 自体が使えなくなったら、`rm ~/.local/bin/gh` で外してから revert する

### 保留した論点

- cloud の PATH がシムを実体より先に解決するかは、環境スナップショットを焼き直してから確かめる
- repo の mise.toml が gh を pin すると、対話 zsh では mise の installs が `~/.local/bin` より前に来てシムが外れる
- repo ごとのシムを mise の `_.path` で重ねる構成。チームで共有する検証を repo 単位で配れるが、今回は個人の全 repo 共通の検証だけを対象にした
