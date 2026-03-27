---
name: ta
description: >-
  会話やプランの内容をもとに、ブランチ作成・コミット・プッシュ・PR 作成を一括実行する。
  ユーザーが /ta と入力したときに使用する。
---

# /ta

変更内容を確認し、以下を順番に実行する:

## 0. ブランチ状態チェック

現在のブランチが `main` でない場合、そのブランチに紐づく PR の状態を確認する:

- `gh pr view --json state` を実行
- **MERGED / CLOSED**: `origin/main` から新規ブランチを作成する（`git checkout -b <branch> origin/main`）
- **OPEN**: 既存ブランチ・PR を再利用し、追加コミットとして push する（新規 PR は作成しない）
- **PR が存在しない**: そのブランチをそのまま使い、新規 PR を作成する

## 1. ブランチ作成（必要な場合のみ）

ステップ 0 で新規作成が必要と判断された場合、`origin/main` から変更内容に適したブランチを新規作成する。worktree でも動作するよう `git checkout main` は使わず、`git fetch origin main && git checkout -b <branch> origin/main` を使用する。

## 2. コミット・push

変更をステージしてコミットし、リモートへ push する。

## 3. PR 作成（必要な場合のみ）

既存の OPEN な PR がない場合、`gh pr create` で PR を作成する。

## 制約

- コミットメッセージはリポジトリの commitlint ルールに従う
- PR タイトルは英語、本文は日本語で記述する
- PR のマージは絶対に実行しない
