# portless の常駐 proxy

[portless](https://github.com/vercel-labs/portless) は worktree ごとに `<名前>.localhost` の URL を割り当てる dev サーバーの proxy。443 で待つ proxy は `portless run` が自動で起動するが、再起動後の初回に sudo を求められる。常駐に登録すると、再起動後も sudo 無しで proxy が立つ。

## 何が動いているか

```text
/Library/LaunchDaemons/sh.portless.proxy.plist   root 所有。port 443、KeepAlive
  │  service install した時点の実体パスが焼き付く
  ├─ ~/.local/share/mise/installs/node/<版>/bin/node
  └─ ~/.local/share/mise/installs/npm-portless/<版>/.../portless/dist/cli.js
```

状態とログは `~/.portless` にある。一部は root 所有。

## 管理の正本

portless 本体は [home/.config/mise/config.toml](../home/.config/mise/config.toml) の `npm:portless` で入れる。常駐 proxy の登録も dotfiles が正本。アプリ側の repo は portless を `portless run` と `portless get` にだけ使う[方針にする](https://github.com/nozomiishii/dev/issues/3070)。

なぜこの分担にしたかは [portless の常駐 proxy はグローバル mise の install から登録する](<decisions/portless の常駐 proxy はグローバル mise の install から登録する.md>)にある。

## 登録する

```shell
mise -C ~ exec -- portless service install
```

sudo は付けない。`service install` が自分で昇格する。`-C ~` は、カレントのプロジェクトの mise.toml が持つ node ではなく、グローバルの node で plist を書かせるため。今の登録はオプションを何も渡していない既定のまま。

## 打ち直す

plist が指すのは版付きのパスなので、node か portless の版が上がっても plist は古い実体を指したままになる。グローバル config の node か `npm:portless` を上げる Renovate の PR を merge したら、登録と同じコマンドを打ち直す。

`service install` は既存の plist を引き継がず、引数と `PORTLESS_*` 環境変数だけから作り直す。`--lan` や `--port` などオプション付きで登録しているときは、先に `portless service status` で設定を控えて同じフラグを付ける。

打ち直す前に旧版の実体が消えると、KeepAlive の proxy が起動失敗をくり返す。

## 外す

```shell
portless service uninstall
```

`~/.portless` と trust store の CA、hosts の記述まで消すときは `portless clean` を使う。

## 確かめる

```shell
portless service status
portless doctor
portless list
```

どれも plist の node パスが古いことは見ない。`doctor` が出す Node.js の版は doctor 自身を動かした node のもので、plist の node ではない。

## 壊れたとき

次の症状が出たら、plist が、消えた node か portless の実体を指している。

- `.localhost` の URL が開けない
- `portless service status` の `Proxy on 443` が `not responding`

[打ち直す](#打ち直す)と直る。
