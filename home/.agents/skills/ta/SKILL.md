---
name: ta
description: >-
  会話やプランの内容をもとに、ブランチ作成・コミット・プッシュ・PR 作成を一括実行する。
  Claude Code で /ta、Codex で $ta と入力したときに使用する。
disable-model-invocation: true
model: sonnet
---

# /ta

`git status --short` と `git diff` で変更内容を把握し、以下を順番に実行する:

## ブランチ判定

現在のブランチを確認する:

- detached HEAD の場合: 先に現在の commit SHA に関連する open PR を GitHub で検索する。1 件あればその PR の head repo と head ref を再利用し、新規 branch や PR を作らない。複数なら候補を示してユーザーに 1 件だけ確認する。0 件の場合だけ新規 branch を作る。`CODEX_THREAD_ID` がある Codex App は current task ID の末尾から lowercase alphanumeric の suffix を作り、`BRANCH="codex/<変更内容>-<task suffix>"` として `git switch -c "$BRANCH"` を実行する。suffix を導出できなければ停止する。Claude Code など他ホストは repo の命名規約で決めた `BRANCH` に同じ command を使う。detached HEAD だけで Codex と推測しない
- `main` 以外のブランチにいる場合: そのブランチに紐づく PR の状態を確認する
  - MERGED / CLOSED: `origin/main` から新規ブランチを作成する
  - OPEN: 既存ブランチ・PR を再利用し、追加コミットとして push する（新規 PR は作成しない）
  - PR が存在しない: そのブランチをそのまま使い、新規 PR を作成する
- `main` にいる場合: 変更内容に適した新規ブランチを `origin/main` から作成する

`main` または MERGED / CLOSED の branch から新規作成する場合は、ホストと repo の命名規約に従った完全な branch 名を `BRANCH` として保持する。`git checkout main` は使わず、`git fetch origin main && git switch -c "$BRANCH" origin/main` を実行する。

## コミット・push

把握した変更のうち関連するものだけをステージしてコミットする。既存の open PR を再利用する場合は、PR の head repository と head ref を取得する。connector が head repository identity と write capability を返せなければ、fork かを推測せず commit 前に停止する。fork PR なら head repo を push remote とし、`git push "$PUSH_REMOTE_URL" "HEAD:refs/heads/$HEAD_REF"` で明示的に push する。base repo の `origin` へ同名 branch を作らない。新規 PR の branch だけ `git push -u origin "$BRANCH"` を使う。無関係な変更を巻き込まない。

base または head が外部 repo、もしくは所有者を判定できない場合は、stage・commit・push・PR 作成より先に sibling の [oss SKILL.md](../oss/SKILL.md) を明示的に読み、その承認境界に従う。

## PR 作成（必要な場合のみ）

既存の OPEN な PR がない場合、PR を作成する。

## PR の監視（pr skill へ引き継ぐ）

PR 作成 / push 完了後、sibling の [pr SKILL.md](../pr/SKILL.md) を明示的に読み、その手順で CI 失敗・レビュー指摘・main との conflict を修復して mergeable まで持っていく。pr skill は explicit-only のため、catalog から暗黙に選ばせない。

ただし PR が draft の場合（tad skill 経由、または `gh pr view --json isDraft` が `true`）はスキップする。draft は修正途中である前提なので、CI の失敗を勝手に直さない。
