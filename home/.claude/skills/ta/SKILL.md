---
name: ta
description: >-
  会話やプランの内容をもとに、ブランチ作成・コミット・プッシュ・PR 作成を一括実行する。
  ユーザーが /ta と入力したときに使用する。
---

# /ta

ta — thanks, mate. ありがとう！議論して、一緒に作り上げた変更を仕上げて届ける。

ユーザーが `/ta` を実行した時点で、コミット・push・PR 作成の明示依頼とみなす。

変更内容を確認し、以下を順番に実行する:

## 0. ブランチ判定

現在のブランチを確認する:

- **`main` 以外のブランチにいる場合**: そのブランチに紐づく PR の状態を確認する
  - **MERGED / CLOSED**: `origin/main` から新規ブランチを作成する
  - **OPEN**: 既存ブランチ・PR を再利用し、追加コミットとして push する（新規 PR は作成しない）
  - **PR が存在しない**: そのブランチをそのまま使い、新規 PR を作成する
- **`main` にいる場合**: 変更内容に適した新規ブランチを `origin/main` から作成する

ブランチ作成時は worktree でも動作するよう `git checkout main` は使わず、`git fetch origin main && git checkout -b <branch> origin/main` を使用する。

## 1. コミット・push

変更をステージしてコミットし、リモートへ push する。

## 2. PR 作成（必要な場合のみ）

既存の OPEN な PR がない場合、PR を作成する。

## 3. PR の監視（/pr へ引き継ぐ）

PR 作成 / push 完了後、続けて `pr` skill を呼び出し、CI 失敗・レビュー指摘・main との conflict を修復して mergeable まで持っていく。

ただし PR が draft の場合（`/tad` 経由、または `gh pr view --json isDraft` が `true`）はスキップする。draft は修正途中である前提なので、CI の失敗を勝手に直さない。

## 制約

- コミットメッセージはリポジトリの commitlint ルールに従う
- PR タイトルは Conventional Commits 形式（英語）で `<type>: <subject>`
  - 許可 type は `feat` / `fix` / `chore`（リポジトリで追加されている場合はそれに従う）
  - subject は小文字始まり / ASCII のみ / 末尾スペース禁止
  - CI の semantic pull request チェック（amannn/action-semantic-pull-request）と同じ規則
- PR 本文は日本語で記述する
- PR のマージは絶対に実行しない
