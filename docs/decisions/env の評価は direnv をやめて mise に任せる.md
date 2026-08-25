---
status: accepted
date: 2026-08-26
---

# env の評価は direnv をやめて mise に任せる

## 背景と課題

env の正本を `.envrc` から `mise.toml` の `[env]` へ移した結果、手元の repo に `.envrc` の実ファイルが 1 つも残らなくなった。dotfiles には direnv 本体の導入 (Brewfile / cloud setup)、shell hook、whitelist だけが残っている。

`.envrc` が担っていた cd 時の副作用は、各 repo の `.hooks/setup.sh` と SessionStart hook へ移した。mise に相当機能が無いのは Nix の flake 連携だけで、手元に `flake.nix` も `shell.nix` も無い。

direnv は env の評価だけでなく、whitelist と `direnv allow` による信頼ゲートも担っていた。

## 検討した選択肢

### 信頼ゲートの置き換え

| 選択肢 | 評価 |
| --- | --- |
| mise の既定のまま | 自分の repo は clone script が clone 直後に trust する。外部 repo は実行時に自動 trust されるため止まらない |
| `paranoid = true` | 自動 trust が止まり direnv に一番近い。config を編集するたび再 trust が要り、worktree 間の trust 共有も無効になる |
| `trusted_config_paths` に prefix を入れる | direnv の whitelist と同じ形だが、prompt を省く設定なのでゲートにはならない |

### 非対話シェルでの実行入口

| 選択肢 | 評価 |
| --- | --- |
| dotfiles のグローバル規約で決める | 手元で `[env]` を持つのは 1 repo だけで、そこに合わせた規約を全 repo に配ることになる |
| 各 repo の mise task に任せる | 実行入口が repo の task 定義と AGENTS.md に集まる |

## 決定

direnv を撤去し、env の評価は mise に任せる。

信頼ゲートは mise の既定のままにする。外部 repo のゲートは弱くなるが、`paranoid` の運用コストに見合わない。

実行入口は各 repo の mise task と AGENTS.md に任せる。`mise activate --shims` は `[env]` を非 mise ツールに渡さないため、env に依存するコマンドは repo 側で task に包む。wt スキルからは env の実行ルールを削る。

[repo をまたぐタスクの ADR](repo%20をまたぐタスクはセッションごと分ける.md)のうち、`direnv が無いときの扱い` の論点と、決定の「環境評価の正本は `.envrc`」「必ず direnv を通す」をここで差し替える。同 ADR の他の柱はそのまま。

## 結果

### 良くなったこと

- 実ファイルが無い機能の導入と設定が消える
- env の正本が各 repo の `mise.toml` 1 箇所になる

### 引き受けたコスト

- 外部 repo の信頼ゲートが弱くなる

### 保留した論点

- 外部 repo を手元で動かす頻度が上がったら `paranoid = true` を再検討する
