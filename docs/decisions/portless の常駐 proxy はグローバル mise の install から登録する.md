---
status: accepted
date: 2026-09-11
---

# portless の常駐 proxy はグローバル mise の install から登録する

## 背景と課題

[portless](https://github.com/vercel-labs/portless) が worktree に配る `<名前>.localhost` の URL は、443 で待つ常駐 proxy が受ける。この proxy は root 所有の LaunchDaemon で、`portless service install` が `/Library/LaunchDaemons/sh.portless.proxy.plist` を書く。

plist に入るのは、実行した時点の node の実体パスと portless の `dist/cli.js` の絶対パス。node は `process.execPath` から取るので symlink が解決され、`installs/node/lts` のような安定したパスから起動しても版付きのパスが焼き付く。この実体が消えると、KeepAlive の proxy が起動失敗をくり返す。

決めるのは 2 つ。portless をどこから入れて登録するかと、版が上がったときに plist をどう追従させるか。

## 検討した選択肢

### portless の置き場と登録元

| 選択肢 | 評価 |
| --- | --- |
| グローバル mise の install から登録する | 版はグローバル config に固定され Renovate が上げる。repo や worktree を消しても実体は残る |
| プロジェクトの mise.toml や repo の node_modules/portless から登録する | repo や worktree を消した時点、prune した時点で proxy が壊れる |
| install.sh や `mise run toolchains` に `service install` を組み込む | 全 Mac に root の LaunchDaemon が入る挙動変更になる |

### 版が上がったときの plist の追従

| 選択肢 | 評価 |
| --- | --- |
| 版が上がるたびに `service install` を打ち直す | 手動で忘れうるが、plist は常に現存の実体を指す |
| plist を手で安定したパスに書き換える | `process.execPath` の symlink 解決で次の `service install` に戻される。root 所有ファイルの手編集は再現性が無い |
| mise の [launchd 管理](https://mise.jdx.dev/bootstrap/launchd.html) (`[bootstrap.macos.launchd.agents]`) で plist を持つ | user agent 専用で、`/Library/LaunchDaemons` の system daemon は対象外。port 443 は root が要る |
| dotfiles で plist を持ち、`$HOME/.local/bin` のスクリプト経由で起動する (この repo の LaunchAgent の型) | LaunchDaemon は root 所有で `/Library/LaunchDaemons` に置くため、user 権限の dotfiles リンクでは張れない。portless の `service` サブコマンドの管理外になり、`service status` と `service uninstall` が使えなくなる |
| Homebrew の node で登録する | Cellar の版付きパスに解決され、brew upgrade で同じことが起きる |
| `upgrade.auto_prune = false` で旧版を残す | `mise upgrade` が置き換えた版にしか効かない。手動の `mise prune` は防げない |
| post-merge の lefthook で plist と現在のグローバル node・portless のパスを突き合わせる | 壊れる引き金の merge と 1 対 1 で警告できる。今は入れない。忘れて壊れてから決める |
| mise のグローバル `[hooks] postinstall` で同じ確認を回す | 全 repo の `mise install` / `mise up` / auto-install で警告が出続ける。他 repo の出力に混ざる。今は入れない |

## 決定

### portless の置き場と登録元

- グローバル config の `[tools]` に `"npm:portless"` を置く
- `mise -C ~ exec -- portless service install` で LaunchDaemon を登録する

proxy の登録は dotfiles を正本にする。アプリ側の repo は devDependency の portless を持つが、登録には使わない。アプリ側も[この分担にする方針](https://github.com/nozomiishii/dev/issues/3070)。

### 版が上がったときの plist の追従

打ち直しは手動にする。グローバル config の node か `npm:portless` が上がったら、登録と同じコマンドを打つ。運用の手順は [portless の常駐 proxy](../portless.md)にある。

## 結果

### 良くなったこと

- proxy の実体が repo や worktree の寿命から切り離された
- 版がグローバル config に固定され、Renovate の PR で上がる
- 登録の正本が dotfiles 1 箇所になった

### 引き受けたコスト

- グローバル config の node か portless の版が上がるたびに打ち直しが要る
- 打ち直しを忘れて `mise prune` すると実体が消え、proxy が壊れる。plist のパスが古いことを検知する手段は無い。各コマンドが何を見るかは[確かめる](../portless.md#確かめる)にある

### 保留した論点

- 打ち直しを忘れない仕組みは入れていない。忘れて壊れてから決める
- 上流への「安定した node のパスで登録する」要望は出していない
