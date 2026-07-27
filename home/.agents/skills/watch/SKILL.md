---
name: watch
description: >-
  外部バグの解消を検知できる形 (expiring TODO・追跡 Issue) で追跡を残す。
  Claude Code で /watch、Codex で $watch と入力した時、Issue 調査で追跡が必要と判断した時、
  または外部バグ・依存制約によるワークアラウンドや一時対応をコードに入れる時に使用する。
argument-hint: "[Issue URL / owner/repo#number]（任意）"
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

追跡対象は入力または Issue URL から `$OWNER`、`$REPO`、`$NUM` に分ける。owner と repo は英数字・`.`・`_`・`-`、`NUM` は正の整数だけを許可し、検証できなければ外部操作へ進まない。検証後に `UPSTREAM_URL="https://github.com/$OWNER/$REPO/issues/$NUM"` とする。

承認を得たら、外部リポジトリへの書き込みより先に sibling の [oss SKILL.md](../oss/SKILL.md) を明示的に読み、その合意・下書き・承認ゲートに従う。サブスクライブも外部状態の変更なので例外にしない。

ゲート通過後、以下を順に実行する:

- 対象 Issue をサブスクライブ:

  ```sh
  TARGET_ID=$(gh issue view "$NUM" --repo "$OWNER/$REPO" --json id --jq .id)
  gh api graphql \
    -f query='mutation($id: ID!) { updateSubscription(input: {subscribableId: $id, state: SUBSCRIBED}) { subscribable { viewerSubscription } } }' \
    -f id="$TARGET_ID"
  ```

- 作業中のリポジトリに `upstream-watch` ラベルがなければ作成: `gh label create upstream-watch --description "外部 Issue の追跡" --color "d4c5f9"`
- 作業中のリポジトリに Issue を発行する。タイトルとボディは以下の形式:

タイトル: `[upstream-watch] $OWNER/$REPO#$NUM の短い要約`

ボディ:

```markdown
## 追跡対象

$UPSTREAM_URL

## きっかけ

この追跡を始めた出来事。何をしていて、どういう問題に遭遇したか。

## 自分への影響

この外部バグが自分の作業にどう影響しているか。

## 解消後のアクション

Issue が解消したら自分が取るべき具体的なアクション。
```

- Issue に `upstream-watch` ラベルを付ける
- 発行した Issue の URL を報告する
