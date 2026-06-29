---
name: routine
description: >-
  新しい Claude Code Routine を追加する。
  .routines/<name>.md の作成 → brain repo に commit & push → /schedule で cloud に登録。
  ユーザーが /routine と入力したとき、または「routine を追加したい」「定期実行を作りたい」と言ったときに使用する。
argument-hint: <routine-name> <概要>
disable-model-invocation: true
---

# /routine

新しい Claude Code Routine を git 管理で追加する。

## 前提

- routine prompt の正本は `nozomiishii/brain` repo の `.routines/<name>.md`
- cloud UI の Instructions は stub（`.routines/<name>.md を Read し、その指示に従って実行せよ。`）
- 全 routine に `nozomiishii/brain` repo をアタッチする

## 手順

### 既存 routine を参考にする

brain repo の `.routines/` を確認し、frontmatter の構造と prompt の書き方を把握する。

```bash
BRAIN="$HOME/Code/nozomiishii/brain"
ls "$BRAIN/.routines/"
```

既存ファイルを 1〜2 件 Read して、frontmatter（name, repos, schedule, model）と prompt 本文のパターンを掴む。

### ユーザーと対話して prompt を設計する

- 対象 repo
- 実行スケジュール（cron 式 + JST 表記）
- model（opus-4-6 / opus-4-7 / sonnet-4-6）
- prompt の目的と内容

`$ARGUMENTS` があればそこから読み取り、不足分だけ聞く。

### `.routines/<name>.md` を作成する

frontmatter 構造:

```yaml
---
name: <kebab-case>
repos: [nozomiishii/<repo>, nozomiishii/brain]
schedule: "<cron>" # HH:MM JST のコメント
model: <model>
---
```

- `repos` には対象 repo と `nozomiishii/brain` の両方を含める
- schedule の cron は UTC で書き、コメントに JST を添える

### brain repo に commit & push

```bash
BRAIN="$HOME/Code/nozomiishii/brain"
git -C "$BRAIN" checkout main
git -C "$BRAIN" pull origin main
# ファイルを配置した後
git -C "$BRAIN" add ".routines/<name>.md"
git -C "$BRAIN" commit -m "feat: add <name> routine prompt"
git -C "$BRAIN" push origin main
```

worktree にいる場合は `git -C` で brain repo を直接操作する。

### cloud UI に routine を登録する

`/schedule` を使って routine を作成する。対話的に以下を設定:

- Instructions: `.routines/<name>.md を Read し、その指示に従って実行せよ。`
- repos: 対象 repo + nozomiishii/brain
- schedule: frontmatter と同じ cron
- model: frontmatter と同じ model

## 制約

- routine prompt は brain repo `.routines/` が正本。cloud UI に prompt 本文を直接書かない
- frontmatter の `repos` に `nozomiishii/brain` を必ず含める
- cron は UTC で記述し、JST をコメントで添える
