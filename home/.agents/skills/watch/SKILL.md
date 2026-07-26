---
name: watch
description: >-
  外部バグの解消を検知できる形 (expiring TODO・追跡 Issue) で追跡を残す。
  Issue 調査の結果、自分では修正できない外部バグの追跡が必要と判断した時、
  または外部のバグ・依存の制約によるワークアラウンド・一時対応をコードに入れる時に使用する。
---

# /watch

自分では直せない外部のバグに当たった時に、解消を機械が検知できる形で追跡を残す。

## 発動条件

以下のどちらかで発動する。

- Issue 調査の結果報告に、次をすべて満たす外部 Issue が含まれる
  - Open である
  - 自分の作業に影響がある
  - 自分では修正できない（他者のリポジトリ、上流のバグ等）
- 外部のバグや依存の制約によるワークアラウンド・一時対応をコードに入れる

時間がない・「余計なことはするな」と指示された・もう回避コードは書き終えた、を発動を省く理由にしない。
expiring TODO はコメント 1 行、追跡 Issue は報告に提案を 1 文添えるだけで、実行はユーザー承認後になる。
後回しにした追跡は戻ってこない。

## 追跡方法の振り分け

解消条件が依存のバージョンで表せて、対象 repo で
[unicorn/expiring-todo-comments](https://github.com/sindresorhus/eslint-plugin-unicorn/blob/main/docs/rules/expiring-todo-comments.md)
が有効な場合、追跡 Issue を作らずコードに expiring TODO を書く。renovate がそのバージョンに
更新した時に lint が発火し、ワークアラウンドの削除を強制する。

```tsx
// TODO [storybook@>=10.5.0]: parameters.htmlLang に移行してこの workaround を削除する
// https://github.com/storybookjs/storybook/pull/35321
```

それ以外（修正がいつ・どのバージョンで入るか不明、lint が無効な repo）は、以下の提案と実行に進む。
ワークアラウンドをコードに入れた場合は、コードのコメントに発行した追跡 Issue の URL を書く。

どちらの場合も、「直ったら戻す」と文章のコメントだけ残して終えない。
lint にも Issue にもつながっていないコメントは放置される。

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
