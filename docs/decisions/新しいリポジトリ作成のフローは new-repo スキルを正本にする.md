# 新しいリポジトリ作成のフローは new-repo スキルを正本にする

Status: accepted
Date: 2026-07-24

## Context — 判断を迫られた状況

新しいリポジトリを作るたびに手戻りが起きていた。直近では nozomiishii/design の作成で、空リポジトリ + main 保護ルールにより initial commit の push が拒否されるデッドロックが発生した。スキルなしのエージェントにリポジトリ作成を依頼する実験では、`gh repo create` / `gh repo edit` / ruleset API の直叩きで IaC を迂回する計画を立てた(観察の逐語とテスト記録は [#1393](https://github.com/nozomiishii/dotfiles/issues/1393))。

## Decision — 決めたこと

- 新しいリポジトリ作成のフローの正本を new-repo スキルに置く
- 役割分担: リポジトリの作成・設定・保護は nozomiishii/infra の `locals.repositories`、ローカル登録は nozomiishii/workspaces の `projects.json`、足場は configs 一式 + nozomiishii/workflows を呼ぶ標準 workflow
- GitHub を直接操作する作成・設定変更(`gh repo create` / `gh repo edit` / ruleset API)は禁止として明文化する
- ブートストラップは `auto_init` 前提(判断は [infra の ADR](https://github.com/nozomiishii/infra/blob/main/docs/decisions/リポジトリ作成時に%20auto_init%20で%20initial%20commit%20を作る.md))
- `@nozomiishii/cspell-config` と `@nozomiishii/markdownlint-cli2-config` は非推奨のため新規リポジトリに導入しない

## Consequences — 決定がもたらすもの

- 以後の新規リポジトリはスキル経由で作り、フローが変わったらスキルを更新する。判断が変わったら新しい ADR を書く
- スキル本文は観察された失敗にだけ対処する最小構成を保ち、テスト(読者テスト・圧力テスト)を経ずに編集しない
