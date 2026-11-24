---
status: accepted
date: 2026-11-23
---

# 外部スキルは vercel-labs/skills で管理し、更新は当面手動とする

## 背景と課題

外部のエージェントスキル（[nanaism/yomiyasu](https://github.com/nanaism/yomiyasu) など）を dotfiles で配布したい。要件は次の 3 つを満たすこと。

- スキル本体を dotfiles の Git リポジトリに同梱しない
- ローカル（Claude Code、Codex、Antigravity）と Cloud 環境（`cloud-setup.tar.gz`）の両方に同じ版を配布する
- 今後ほかの外部スキルを増やしたときも、同じ仕組みで追加できる

あわせてバージョン更新を Renovate で自動化できるかも検討した。決定後の配布構成は次の通り。

```text
home/skills-lock.json (commit と computedHash を固定)
  │
  ├─ ローカル (install.sh / lefthook post-merge)
  │    └─ mise run skills (skills install --frozen-lockfile -a codex)
  │         └─ home/.agents/skills/<name>/ (.gitignore)
  │              └─ 既存 symlink 経由で Claude Code / Codex / Antigravity へ届く
  │
  └─ Cloud 環境 (cloud-setup.yaml)
       └─ deploy ジョブで mise run skills を実行し、cloud-setup.tar.gz へ同梱
```

## 検討した選択肢

### 配布・管理ツールの選定

| 選択肢 | 評価 |
| --- | --- |
| [vercel-labs/skills](https://github.com/vercel-labs/skills)（採用） | 広く使われているスキル CLI であり、`skills-lock.json` v2 で `commit` と `computedHash` を記録する。任意の Git リポジトリのスキルを `skills add` で追加でき、自前のコピー用スクリプトが要らない。Renovate はまだ公式対応していない[^renovate-skills-lock] |
| [mise の `github:` backend](https://mise.jdx.dev/dev-tools/backends/github.html)（見送り） | `mise.toml` と `mise.lock` で Renovate の自動更新に乗せられる。ただし対象は GitHub Releases で zip や tar.gz を配布するスキルに限られ、展開先から `home/.agents/skills/` へ運ぶ自前スクリプトも必要になる |
| [microsoft/apm](https://github.com/microsoft/apm)（見送り） | `apm.yml` と `apm.lock.yaml` で宣言管理でき、Renovate の公式マネージャもある[^renovate-apm]。ただし v0.37 時点で開発途上であり、利用者数では `vercel-labs/skills` に及ばない |
| リポジトリへの同梱（見送り） | 外部スキルの全ファイル（`yomiyasu` 単体で約 2.8 万行）が dotfiles の Git リポジトリに残り、更新のたびに大きな差分が出る |
| `gh skill`（見送り） | 追加パッケージなしで `--pin` 固定できるが、宣言ファイルやロックファイルを持たない |

### 更新の運用方法

| 選択肢 | 評価 |
| --- | --- |
| 当面は手動で `skills update` を実行し、毎月自動更新手段を見直す（採用） | ロック整合のためのカスタムマネージャや回避スクリプトを持たずに済む。エコシステムが整った段階で移行しやすい |
| Renovate のカスタムマネージャで `skills-lock.json` を追う（見送り） | `computedHash` はスキルフォルダ全体から計算する独自ハッシュであり、Renovate 側で更新できない。PR ごとに手元でハッシュを再生成する必要があり、自動マージが成立しない |

## 決定

### 配布・管理ツール

- 外部スキルの管理には `vercel-labs/skills`（`npm:skills`）を使う
- 宣言と版固定の正本は `home/skills-lock.json` とし、`~` へはリンクしない
- 展開先の外部スキルディレクトリは `.gitignore` で追跡対象外とする
- 復元処理は `mise.toml` の `[tasks.skills]` に集約し、`install.sh`・`lefthook` の `post-merge`・`cloud-setup.yaml` から共通で呼び出す
- `-a codex` を指定すると共通の `.agents/skills/` へ展開されるため、既存の symlink 構成を崩さず複数エージェントへ配布する

### 更新の運用

- 更新は当面、手動で `skills update` を実行して PR を作成する
- Renovate の `skills-lock.json` 対応や `microsoft/apm` の成熟度は、[自動更新手段の月次見直し issue](https://github.com/nozomiishii/dotfiles/issues/2123) に記録し、毎月確認する

## 結果

### 良くなったこと

- スキル本体を Git リポジトリに置かずに、ローカルと Cloud の両方へ同じ版を配布できる
- コピーや退避を行う自前スクリプトを持たずに済む
- 新しい外部スキルも `skills add` と `.gitignore` への追記だけで増やせる

### 引き受けたコスト

- 外部スキルの更新を手動で実行する手間が残る
- `mise.toml` に管理対象のツールとして `npm:skills` が増える
- 外部スキルを追加するたびに `.gitignore` へ展開先ディレクトリを 1 行足す必要がある

### 保留した論点

- Renovate が `skills-lock.json` に公式対応したとき、または別の宣言ツールへ移行すべきと判断したときの切り替え手順は、移行時に決める

[^renovate-skills-lock]: [Renovate Discussion: Support skills-lock.json](https://github.com/renovatebot/renovate/discussions/41861)
[^renovate-apm]: [Renovate APM マネージャのドキュメント](https://docs.renovatebot.com/modules/manager/apm/)
