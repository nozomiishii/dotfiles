---
status: accepted
date: 2026-07-24
---

# 新しいリポジトリ作成のフローは new-repo スキルを正本にする

## 背景と課題

新しいリポジトリを作るたびに手戻りが起きていた。直近では nozomiishii/design の作成で、空リポジトリ + main 保護ルールにより initial commit の push が拒否されるデッドロックが発生した。

## 検討した選択肢

- スキルを置かない: スキルなしのエージェントにリポジトリ作成を依頼する実験では、`gh repo create` / `gh repo edit` / ruleset API の直叩きで IaC を迂回する計画を立てた (観察の逐語とテスト記録は [#1393](https://github.com/nozomiishii/dotfiles/issues/1393))
- new-repo スキルを正本にする: 作成・設定・保護を IaC に寄せ、直叩きの禁止を明文化できる

## 決定

新しいリポジトリ作成のフローの正本を new-repo スキルに置く。役割分担は次のとおり。

| 役割 | 持ち場 |
| --- | --- |
| リポジトリの作成・設定・保護 | nozomiishii/infra の `locals.repositories` |
| ローカル登録 | nozomiishii/infra の `projects.json` |
| 初期セットアップ | configs 一式 + nozomiishii/workflows を呼ぶ標準 workflow |

- GitHub を直接操作する作成・設定変更 (`gh repo create` / `gh repo edit` / ruleset API) は禁止として明文化する
- ブートストラップは `auto_init` 前提 (判断は [infra の ADR](https://github.com/nozomiishii/infra/blob/main/docs/decisions/リポジトリ作成時に%20auto_init%20で%20initial%20commit%20を作る.md))
- `@nozomiishii/cspell-config` と `@nozomiishii/markdownlint-cli2-config` は非推奨のため新規リポジトリに導入しない

## 結果

### 良くなったこと

- 以後の新規リポジトリはスキル経由で作り、フローが変わったらスキルを更新する。判断が変わったら新しい ADR を書く

### 引き受けたコスト

- スキル本文は観察された失敗にだけ対処する最小構成を保ち、テスト (読者テスト・圧力テスト) を経ずに編集しない

### 保留した論点

なし
