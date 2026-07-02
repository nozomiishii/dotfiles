---
name: routine
description: >-
  Claude Code Routine の追加・変更。
  .routines/<name>.md の作成/編集 → brain repo に PR 作成 → /schedule で cloud trigger と同期。
  ユーザーが /routine と入力したとき、「routine を追加したい」「定期実行を作りたい」と言ったとき、
  または .routines/ の設定を変更したとき（model / schedule / repos の変更を含む）に使用する。
argument-hint: <routine-name> <概要>
---

# /routine

Claude Code Routine を git 管理で追加・変更する。

## 前提

- routine prompt の正本は `nozomiishii/brain` repo（`~/Code/nozomiishii/brain`）の `.routines/<name>.md`
- cloud trigger の Instructions は stub（`.routines/<name>.md を Read し、その指示に従って実行お願い。`）
- 全 routine に `nozomiishii/brain` repo をアタッチする
- `.routines/` の frontmatter と cloud trigger は二重管理。片方を変えたら必ず両方更新する
- `.routines/` の frontmatter は brain repo の pre-commit（`scripts/lint-frontmatter.ts` + `scripts/schemas/claude/routines.ts`）で検証される。cron と JST コメントの整合も見られる

## 新規追加

### 既存 routine を参考にする

brain repo の `.routines/` を確認し、frontmatter の構造と prompt の書き方を把握する。

```bash
BRAIN="$HOME/Code/nozomiishii/brain"
ls "$BRAIN/.routines/"
```

既存ファイルを 1〜2 件 Read して、frontmatter（name, type, repos, schedule, model）と prompt 本文のパターンを掴む。

### ユーザーと対話して routine を設計する

`$ARGUMENTS` があればそこから読み取り、不足分だけ 1 つずつ聞く。

#### 目的のすり合わせ

- この routine で何を達成したいか
- 手動で今やっている作業の自動化か、新しい情報収集か
- 成果物は何か（GitHub issue、PR、Slack 通知、レポート等）
- 成功・失敗の判断基準

#### 設計の検討

- 対象 repo と、routine がアクセスする外部リソース
- 実行頻度の妥当性（daily / weekly / monthly、曜日・時刻）
- model の選定（調査・要約中心なら sonnet、判断・分析が必要なら opus）
- 既存 routine と責務が被らないか（`.routines/` の一覧を見て確認）
- エラー時の振る舞い（部分的な結果で続行するか、止めるか）

#### 型を決める

routine を 4 つの型のどれかに分類する。型ごとの雛形が `.routines/_templates/<type>.md` にあり、frontmatter の `type` は使った雛形の名前になる。

- news: 定期的な情報収集。収集期間フィルタ、TL;DR、前回 issue へのリンク
- watch: 条件検出まで見張る。ベースライン、判定基準、検出時フラグ、終了条件（目的達成を検出したら issue で routine の停止を提案する）
- audit: 自リソースの定点監査。対象選定ロジック、過去の意思決定との照合（却下・保留済みの再提案禁止）
- reminder: 手動作業の催促。手順チェックリスト、完了ログ

#### prompt の構成を決める

既存 routine の共通パターンを踏まえて構成を提案する:
- 前提（実行環境、認証状態、repo の状態）
- タスク（具体的な手順）
- 出力フォーマット（issue / comment のテンプレート）
- 制約（やらないこと、エラー時の挙動）

ユーザーが納得するまで議論を続け、合意できてから `.routines/<name>.md` の作成に進む。

### `.routines/<name>.md` を作成する

`.routines/_templates/<type>.md` をコピーし、`<...>` の placeholder と各セクションを埋める。

- `repos` には対象 repo と `nozomiishii/brain` の両方を含める
- schedule の cron は UTC で書き、コメントに JST を添える（20:00 UTC = 翌日 05:00 JST。日またぎで曜日・日付がずれる点に注意）
- 雛形にないセクションの追加は自由。雛形の必須セクションを削る場合は理由をユーザーと合意する

### brain repo に PR 作成

```bash
BRAIN="$HOME/Code/nozomiishii/brain"
SLUG="routine-<name>"
git -C "$BRAIN" fetch origin main --quiet
git -C "$BRAIN" worktree add "$BRAIN/.claude/worktrees/$SLUG" -b "$SLUG" origin/main
```

worktree 内にファイルを配置した後、commit → push → PR 作成:

```bash
WT="$BRAIN/.claude/worktrees/$SLUG"
git -C "$WT" add ".routines/<name>.md"
git -C "$WT" commit -m "feat: add <name> routine prompt"
git -C "$WT" push -u origin "$SLUG"
gh pr create -R nozomiishii/brain --base main --head "$SLUG" \
  --title "feat: add <name> routine prompt" \
  --body "（日本語の PR 本文）"
```

### cloud trigger を登録する

`/schedule` を使って routine を作成する。対話的に以下を設定:

- Instructions: `.routines/<name>.md を Read し、その指示に従って実行お願い。`
- repos: 対象 repo + nozomiishii/brain
- schedule: frontmatter と同じ cron
- model: frontmatter と同じ model

### 発火時刻の確認

登録・更新のレスポンスには `next_run_at`（UTC）が含まれる。JST に換算し、frontmatter の schedule コメントと並べて提示する。ユーザーが「意図した曜日・時刻に発火する」ことを確認して完了とする。ずれていたら cron を直してやり直す。

## 変更・同期

`.routines/` の frontmatter を変更した場合、cloud trigger も同期する。

### 変更対象の検出

```bash
git diff origin/main...HEAD --name-only -- '.routines/'
```

diff がない場合（直接 frontmatter を変更する依頼の場合）は先にファイルを編集する。

### cloud trigger との同期

`schedule` skill の `RemoteTrigger` ツールで全 trigger を list し、変更ファイルの frontmatter `name` で照合する。差分がある frontmatter フィールドだけ update する:

- `model` → `job_config.ccr.session_context.model`（frontmatter 値に `claude-` を prefix）
- `schedule` → `cron_expression`
- `type` → 同期しない（`.routines/` ローカル専用のフィールド）

update 時は `environment_id` を既存 trigger から取得して含める（API が要求するため）。照合できない routine はスキップし、ユーザーに報告する。

schedule を update した場合は、レスポンスの `next_run_at` を JST に換算し frontmatter の schedule コメントと並べて提示する（発火時刻の確認と同じ手順）。

## 整合性チェック

新規追加・変更・同期の最後に、全 routine の frontmatter と cloud trigger の整合性を検証する。

`schedule` skill の `RemoteTrigger` で全 trigger を list し、`.routines/` の全 frontmatter と突き合わせる。

検証項目:

- `schedule`: frontmatter の cron と trigger の `cron_expression` が一致するか
- `model`: frontmatter の model と trigger の `session_context.model` が一致するか（`claude-` prefix を考慮）
- `repos`: frontmatter の repos と trigger の `sources` が一致するか
- `prompt`: trigger の events に `.routines/<name>.md を Read し、その指示に従って実行お願い。` が設定されているか

差分があればユーザーに報告し、修正するか確認する。

## 制約

- routine prompt は brain repo `.routines/` が正本。cloud trigger に prompt 本文を直接書かない
- frontmatter の `repos` に `nozomiishii/brain` を必ず含める
- cron は UTC で記述し、JST をコメントで添える
- frontmatter を変更したら cloud trigger も必ず同期する
