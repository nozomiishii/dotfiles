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

#### prompt の構成を決める

既存 routine の共通パターンを踏まえて構成を提案する:
- 前提（実行環境、認証状態、repo の状態）
- タスク（具体的な手順）
- 出力フォーマット（issue / comment のテンプレート）
- 制約（やらないこと、エラー時の挙動）

ユーザーが納得するまで議論を続け、合意できてから `.routines/<name>.md` の作成に進む。

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
