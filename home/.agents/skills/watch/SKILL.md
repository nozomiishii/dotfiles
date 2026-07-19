---
name: watch
description: >-
  外部 Issue の追跡を提案し、サブスクライブと追跡 Issue の発行を行う。
  Issue 調査の結果、自分では修正できない外部バグの追跡が必要と判断した時に使用する。
---

# /watch

Issue 調査の結果を報告した時に、追跡が必要な外部 Issue があれば自動で提案する。

## 発動条件

Issue 調査の結果報告に、以下をすべて満たす外部 Issue が含まれる場合:

- Open である
- 自分の作業に影響がある
- 自分では修正できない（他者のリポジトリ、上流のバグ等）

## 提案

ユーザーに「この Issue を追跡しますか？」と確認する。承認なしに次に進まない。

提案時に以下を提示する:

- 追跡対象の Issue リンク
- 追跡する理由（自分への影響）
- Issue が解消したら自分が取るべきアクション

## 実行

承認を得たら、以下を順に実行する:

- 対象 Issue をサブスクライブ: `gh api graphql -f query='mutation { updateSubscription(input: {subscribableId: "'$(gh issue view {number} --repo {owner}/{repo} --json id --jq .id)'", state: SUBSCRIBED}) { subscribable { viewerSubscription } } }'`
- 作業中のリポジトリに `upstream-watch` ラベルがなければ作成: `gh label create upstream-watch --description "外部 Issue の追跡" --color "d4c5f9"`
- 作業中のリポジトリに Issue を発行する。タイトルとボディは以下の形式:

タイトル: `[upstream-watch] {対象リポジトリ}#{番号} の短い要約`

ボディ:

```
## 追跡対象

{対象 Issue の URL}

## きっかけ

{この追跡を始めた出来事。何をしていて、どういう問題に遭遇したか}

## 自分への影響

{この外部バグが自分の作業にどう影響しているか}

## 解消後のアクション

{Issue が解消したら自分が取るべき具体的なアクション}
```

- Issue に `upstream-watch` ラベルを付ける
- 発行した Issue の URL を報告する
