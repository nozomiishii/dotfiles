---
name: tha
description: >-
  会話やプランの内容をもとに、ブランチ作成・コミット・プッシュ・PR 作成を一括実行する。
  Claude Code で /tha、Codex で $tha と入力したときに使用する。
disable-model-invocation: true
model: sonnet
---

# /tha

`git status --short` と `git diff` で変更内容を把握し、以下を順番に実行する:

## GitHub へのアクセス

base branch の解決、ブランチ判定での PR 検索、既存 PR の状態・head 情報の取得、新規 PR 作成、draft 判定、pr skill への引き継ぎ後の状態取得は、利用可能な GitHub connector / app を自分で検索して行う。connector の機能名は固定しない。connector が使える間は、gh CLI が導入・認証済みでも GitHub 操作には使わない。

connector が見つからない・認証切れ・接続失敗の場合は、認証済みの gh CLI に fallback して同じ操作を行う（default branch は `gh repo view --json defaultBranchRef`、PR の検索・作成は `gh pr list` / `gh pr create`）。fallback したことと理由を最後の報告に含める。fallback 中も merge 系（`gh pr merge`、merge endpoint への `gh api`）は実行しない。merge 禁止は backend に依らずこの skill の制約として適用される（Claude Code では gh 側の permissions deny でも封じられている）。gh も未認証なら GitHub 操作を始めず、必要な設定をユーザーに伝えて停止する。

利用中の backend（connector または gh）が対象 PR に必要な head repository identity または write capability を返せない場合は、fork かを推測せず停止する。local branch の作成、stage、commit、push は引き続き git で行い、connector に置き換えない。

## base branch の解決

branch 判定より先に、利用中の backend の repository metadata capability から default branch 名を `BASE_REF` として取得する。`BASE_REF` が空、または `git check-ref-format --branch "$BASE_REF"` に失敗したら fetch や branch 作成へ進まない。

## ブランチ判定

現在のブランチを確認する:

- detached HEAD の場合: 先に現在の commit SHA に関連する open PR を GitHub で検索する。1 件あればその PR の head repo と head ref を再利用し、新規 branch や PR を作らない。複数なら候補を示してユーザーに 1 件だけ確認する。0 件の場合だけ新規 branch を作る。`CODEX_THREAD_ID` がある Codex App は current task ID の末尾から lowercase alphanumeric の suffix を作り、`BRANCH="codex/<変更内容>-<task suffix>"` として `git switch -c "$BRANCH"` を実行する。suffix を導出できなければ停止する。Claude Code など他ホストは repo の命名規約で決めた `BRANCH` に同じ command を使う。detached HEAD だけで Codex と推測しない
- `$BASE_REF` 以外のブランチにいる場合: そのブランチに紐づく PR の状態を確認する
  - MERGED / CLOSED: `origin/$BASE_REF` から新規ブランチを作成する
  - OPEN: 既存ブランチ・PR を再利用し、追加コミットとして push する（新規 PR は作成しない）
  - PR が存在しない: そのブランチをそのまま使い、新規 PR を作成する
- `$BASE_REF` にいる場合: 変更内容に適した新規ブランチを `origin/$BASE_REF` から作成する

`$BASE_REF` または MERGED / CLOSED の branch から新規作成する場合は、ホストと repo の命名規約に従った完全な branch 名を `BRANCH` として保持する。base branch は checkout せず、`git fetch origin "$BASE_REF" && git switch -c "$BRANCH" "origin/$BASE_REF"` を実行する。

## コミット・push

把握した変更のうち関連するものだけをステージしてコミットする。既存の open PR を再利用する場合は、PR の head repository と head ref を取得する。connector が head repository identity と write capability を返せなければ、fork かを推測せず commit 前に停止する。fork PR なら head repo を push remote とし、`git push "$PUSH_REMOTE_URL" "HEAD:refs/heads/$HEAD_REF"` で明示的に push する。base repo の `origin` へ同名 branch を作らない。新規 PR の branch だけ `git push -u origin "$BRANCH"` を使う。無関係な変更を巻き込まない。

base または head が外部 repo、もしくは所有者を判定できない場合は、stage・commit・push・PR 作成より先に sibling の [oss SKILL.md](../oss/SKILL.md) を明示的に読み、その承認境界に従う。

## PR 作成（必要な場合のみ）

既存の OPEN な PR がない場合、connector の PR 作成 capability で PR を作成する。

## PR の監視（pr skill へ引き継ぐ）

PR 作成 / push 完了後、sibling の [pr SKILL.md](../pr/SKILL.md) を明示的に読み、その手順で CI 失敗・レビュー指摘・base branch との conflict を修復して mergeable まで持っていく。PR 番号または URL と利用中の backend（connector または gh fallback）を引き継ぎ、pr skill の「GitHub へのアクセス」と同じ backend 選択手順を使う。pr skill は explicit-only のため、catalog から暗黙に選ばせない。

ただし connector が返す PR metadata で draft の場合はスキップする。draft は修正途中である前提なので、CI の失敗を勝手に直さない。
