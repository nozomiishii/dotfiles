---
name: watch
description: >-
  外部 Issue の調査で継続追跡が必要になったとき、または外部バグや依存制約の一時対応をコードへ入れるときに使用する。
argument-hint: "[Issue URL / owner/repo#number]（任意）"
---

# /watch

自分では直せない外部の問題を、解消を検知できる形で追跡する。

## 発動条件

次のいずれかで発動する。

- 調査した外部 Issue が open で、自分の作業に影響し、自分では修正できない
- 外部バグや依存制約による workaround または一時対応をコードへ入れる

時間がないことや、回避コードを書き終えたことを理由に追跡を省かない。

## 追跡方法を決める

解消条件を依存バージョンで表せ、対象リポジトリで `unicorn/expiring-todo-comments` が有効な場合は expiring TODO を使う。依存更新時の lint で workaround の削除を要求できる形にする。

```tsx
// TODO [storybook@>=10.5.0]: parameters.htmlLang に移行してこの workaround を削除する
// https://github.com/storybookjs/storybook/pull/35321
```

修正時期やバージョンが不明な場合、または lint が無効な場合は追跡 Issue を使う。workaround をコードへ入れた場合は、コメントに追跡 Issue の URL を含める。

どちらの場合も、機械的な検知先に結び付かないコメントだけで終えない。

## 提案する

追跡 Issue を使う場合は、実行前に次を示し、「この Issue を追跡しますか？」とユーザーに確認する。

- 追跡対象の Issue
- 自分の作業への影響
- 解消後に取るアクション

承認後、外部リポジトリの購読状態を変更する前に sibling の [oss SKILL.md](../oss/SKILL.md) を読み、その合意、下書き、承認の境界に従う。

## 追跡を作る

入力から owner、repo、Issue 番号を取り出す。owner と repo は英数字、`.`、`_`、`-` のみ、Issue 番号は正の整数に限定する。検証できなければ外部状態を変更しない。

承認後に次を達成する。

- 外部 Issue を購読する
- 作業中のリポジトリに `upstream-watch` ラベルを用意する。説明は「外部 Issue の追跡」、色は `d4c5f9` とする
- 作業中のリポジトリに追跡 Issue を作り、`upstream-watch` ラベルを付ける
- workaround がある場合は、そのコメントから追跡 Issue へ到達できるようにする

追跡 Issue のタイトルは `[upstream-watch] <owner>/<repo>#<number> の短い要約` とする。本文は次の形にする。

```markdown
## 追跡対象

<外部 Issue の URL>

## きっかけ

<何をしていて、どの問題に遭遇したか>

## 自分への影響

<外部の問題が自分の作業へ与えている影響>

## 解消後のアクション

<Issue が解消した後に行う具体的な作業>
```

作成した追跡 Issue の URL を報告する。
