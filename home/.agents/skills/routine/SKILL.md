---
name: routine
description: >-
  Claude Code Routine の追加・変更。
  .routines/NAME.md の作成・編集 → brain repo に PR 作成 → Claude Code の cloud trigger と同期。
  Claude Code では /routine のほか、「routine を追加したい」「定期実行を作りたい」または .routines/ の設定変更時に使用する。
  Codex では Claude Code Routine を操作する意図で $routine を明示したときだけ使用する。
argument-hint: <routine-name> <概要>
---

# /routine

Claude Code Routine を git 管理で追加・変更する。

Codex から実行する場合も管理対象は Claude Code Routine。Codex の Scheduled task や automation へ置き換えない。cron、Claude model 名、RemoteTrigger のデータモデルを Codex automation の値へ変換しない。

## 前提

- Routines は Claude Code の定期実行機能 <https://code.claude.com/docs/ja/routines>
- routine prompt の正本は `nozomiishii/brain` repo の `.routines/<name>.md`。repo の配置場所は固定しない
- cloud trigger の Instructions は stub（`.routines/<name>.md を Read し、その指示に従って実行お願い。`）
- 全 routine に `nozomiishii/brain` repo をアタッチする
- `.routines/` の frontmatter と cloud trigger は二重管理。frontmatter を先に main へ merge し、merge 後の再実行で trigger を同期する
- `.routines/` の frontmatter は brain repo の pre-commit（`scripts/lint-frontmatter.ts` + `scripts/schemas/claude/routines.ts`）で検証される。発火時刻の正しさは lint でなく trigger 登録・更新時の `next_run_at` 確認で担保する

## trigger 操作の選択

- Claude Code: `schedule` skill と RemoteTrigger を使う
- Codex: `$chrome:control-chrome` を読み、認証済み Chrome で [Claude Code の Routine 管理画面](https://claude.ai/code/routines)を開く。browser-client に network log と API request の capability があれば、UI 操作より先に list / create / update の endpoint と request schema を確認して同じ API を呼ぶ。現在の接続でそれらが利用できない場合は endpoint を推測せず、認証済み UI で同じ項目を操作する

Codex は Routine 管理画面を開いた tab ID と bootstrap URL を固定する。全 read、API request、click、input の直前に、固定した tab ID・`https://claude.ai` origin・`/code/routines` で始まる path が一致することを確認する。不一致なら trigger 情報を送受信せず停止する。

Codex から Claude Code 側の trigger を読めない場合は、Codex automation で代替せず停止する。`.routines/` と trigger の二重管理を片側だけ更新しない。

UI fallback は `name`、`instructions`、`repos`、`schedule`、`model` と、更新後の正確な `next_run_at` をすべて取得できる場合だけ使う。model または raw `next_run_at` が UI に無い場合は、brain repo や trigger を変更する前に停止し、Claude Code で `/routine` を実行する必要があると報告する。相対表示の「tomorrow at 5:00 AM」を raw `next_run_at` の代わりにしない。

## 新規追加

### 既存 routine を参考にする

brain repo の `.routines/` を確認し、frontmatter の構造と prompt の書き方を把握する。

git remote が `nozomiishii/brain` を指す clone をホストの project 一覧または既存の local clone から探し、その絶対パスを `BRAIN` とする。sibling の [wt SKILL.md](../wt/SKILL.md) を明示的に読む。clone が見つからなければ、その repo 準備手順を使う。

```bash
ls "$BRAIN/.routines/"
```

既存ファイルを 1〜2 件読み、frontmatter（name, type, repos, schedule, model）と prompt 本文のパターンを掴む。

### ユーザーと対話して routine を設計する

スキルを呼び出した発話に指定があればそこから読み取り、不足分だけ 1 つずつ聞く。

routine name は `^[a-z0-9]+(?:-[a-z0-9]+)*$` に一致する値だけを受け付ける。file path、branch、title に入れる前に検証し、slash、`..`、空白、shell metacharacter を含む値は拒否する。

name とファイル名を `<頻度>-<対象>` の形に揃える。頻度語は schedule の発火間隔から選ぶ。daily, weekly, biweekly, monthly, quarterly, biannual。

頻度は省かない。当てはまる語が無い、既存語と紛らわしいと感じたときも、最も近い語を選ぶ。平日のみの毎日は daily、隔週は biweekly。既存 routine の name がこの形でない場合も、新しい name はこの形にする。

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
- connector の要否。既定は無し。prompt の手順が MCP ツールを必要とするときだけ足す
- エラー時の振る舞い（部分的な結果で続行するか、止めるか）

#### monthly の発火日を決める

monthly は同じ日に 2 件以上重ねない。重ねるとその日のタスクが一度に膨らむ。

- `.routines/monthly-*.md` を見て空いている最小の日を取る。ファイル名の 2 桁が JST の発火日
- name とファイル名は `monthly-<2 桁の JST 発火日>-<内容>`
- 発火は 05:00 JST に揃える。cron は `0 20 <JST の発火日 - 1> * *`
- 使える日は JST 2〜28 日。1 日は UTC では前月末日にあたり、月末日が 28〜31 と変わるため cron で書けない。29〜31 日も無い月がある

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
- `connectors` には使う connector 名だけを書く。使わないなら `[]`
- schedule の cron は UTC で書き、コメントに JST を添える（20:00 UTC = 翌日 05:00 JST。日またぎで曜日・日付がずれる点に注意）
- 雛形にないセクションの追加は自由。雛形の必須セクションを削る場合は理由をユーザーと合意する

### brain repo に PR 作成

wt skill で brain repo の worktree を作る。REPO は特定済みの `BRAIN`。Claude Code の branch 名は `routine-<name>`、Codex は `codex/routine-<name>-<task suffix>`。作成結果の絶対パスを `WT`、実際の branch 名を `BRANCH` として保持し、ホスト固有の配置場所から再構築しない。

worktree 内にファイルを配置した後、commit → push → PR 作成:

```bash
git -C "$WT" add ".routines/<name>.md"
git -C "$WT" commit -m "feat: add <name> routine prompt"
git -C "$WT" push -u origin "$BRANCH"
BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/routine-pr.XXXXXX")
chmod 600 "$BODY_FILE"
trap 'rm -f -- "$BODY_FILE"' EXIT
printf '%s\n' '（日本語の PR 本文）' > "$BODY_FILE"
PR_URL=$(gh pr create -R nozomiishii/brain --base main --head "$BRANCH" \
  --title "feat: add <name> routine prompt" \
  --body-file "$BODY_FILE")
printf '%s\n' "$PR_URL"
```

PR URL と、merge 後に Claude Code では `/routine <name> sync`、Codex では `$routine <name> sync` を再実行することを報告して、ここで終了する。未merge の `.routines/<name>.md` に対する trigger の create / update は停止する。

## trigger mutation の共通ゲート

cloud trigger を create / update する前に、brain repo で `git fetch origin main` を実行する。同期対象の `.routines/<name>.md` が `origin/main` に merge済みであり、今回ユーザーと合意した内容と byte-for-byte で一致することを `git show "origin/main:.routines/<name>.md"` と `cmp` で確認する。

ローカル branch または open PR にだけ変更がある未merge状態なら、trigger 操作前に停止する。PR URL と merge 後の再実行方法を報告する。PR の作成と trigger mutation を同じ実行で連続して行わない。

### merge 後に cloud trigger を登録する

共通ゲートを通過した再実行でだけ、「trigger 操作の選択」で選んだ手段を使って routine を作成する。以下を設定:

- Instructions: `.routines/<name>.md を Read し、その指示に従って実行お願い。`
- repos: 対象 repo + nozomiishii/brain
- schedule: frontmatter と同じ cron
- model: frontmatter と同じ model
- connectors: frontmatter と同じ connector

trigger を新規作成すると、アカウントで有効な connector がすべて自動で付く。connector が付いた routine は実行中にその全ツールを無確認で使えるため、作成直後に [Routine 管理画面](https://claude.ai/code/routines) の Edit を開き、frontmatter の `connectors` と一致させる。API では connector を変更・削除できない。

### 発火時刻の確認

登録・更新のレスポンスには `next_run_at`（UTC）が含まれる。JST に換算し、frontmatter の schedule コメントと並べて提示する。ユーザーが「意図した曜日・時刻に発火する」ことを確認して完了とする。ずれていたら cron を直してやり直す。

## 変更・同期

`.routines/` の frontmatter を変更した場合、変更 PR を作って終了する。main への merge 後に skill を再実行し、共通ゲートを通過してから cloud trigger を同期する。

### 変更対象の検出

```bash
git diff origin/main...HEAD --name-only -- '.routines/'
```

diff がない場合（直接 frontmatter を変更する依頼の場合）は先にファイルを編集する。diff ができたら commit・push・PR 作成まで進め、trigger は変更せず終了する。

### cloud trigger との同期

共通ゲートを通過した再実行で、「trigger 操作の選択」で選んだ手段で全 trigger を list し、`origin/main` の frontmatter `name` で照合する。差分がある frontmatter フィールドだけ update する:

- `model` → `job_config.ccr.session_context.model`（frontmatter 値に `claude-` を prefix）
- `schedule` → `cron_expression`
- `connectors` → `mcp_connections`。API では変更できないため [Routine 管理画面](https://claude.ai/code/routines) の Edit で操作する
- `type` → 同期しない（`.routines/` ローカル専用のフィールド）

update 時は `environment_id` を既存 trigger から取得して含める（API が要求するため）。照合できない routine はスキップし、ユーザーに報告する。

`name` を変えた場合は照合キーが変わる。PR のリネーム検出で旧 name を特定し、旧 name の trigger を新 name へ update する。trigger の `name` と events の `.routines/<name>.md` の両方を書き換える。delete して作り直すと実行履歴が切れる。

schedule を update した場合は、レスポンスの `next_run_at` を JST に換算し frontmatter の schedule コメントと並べて提示する（発火時刻の確認と同じ手順）。

## 整合性チェック

新規追加・変更・同期のどの経路でも、終了前に必ず実行する。結果は差分ゼロでも表で提示する。表を出さずに終了していたらチェック漏れ。

「trigger 操作の選択」で選んだ手段で全 trigger を list し、`.routines/` の全 frontmatter と突き合わせる。

検証項目:

- `name`: trigger 名が frontmatter の `name` と一致するか。照合キーのため、不一致だと以後の同期で照合できない
- `schedule`: frontmatter の cron と trigger の `cron_expression` が一致するか
- `model`: frontmatter の model と trigger の `session_context.model` が一致するか（`claude-` prefix を考慮）
- `repos`: frontmatter の repos と trigger の `sources` が一致するか
- `connectors`: frontmatter の connectors と trigger の `mcp_connections` が一致するか
- `prompt`: trigger の events に `.routines/<name>.md を Read し、その指示に従って実行お願い。` が設定されているか

trigger 側で値が未設定の場合も差分として扱う。

結果は routine × 検証項目の表で提示する。差分があれば修正するか確認する。

## 制約

- routine prompt は brain repo `.routines/` が正本。cloud trigger に prompt 本文を直接書かない
- frontmatter の `repos` に `nozomiishii/brain` を必ず含める
- trigger の connector は frontmatter の `connectors` に揃える。新規作成では自動で付くため必ず確認する
- monthly の発火日は JST 2〜28 日から空き日を選び、name とファイル名の 2 桁に入れる
- cron は UTC で記述し、JST をコメントで添える
- frontmatter を変更したら main への merge 後に skill を再実行し、cloud trigger も必ず同期する
- 整合性チェックを実行せずに終了しない。差分ゼロでも結果の表を提示する
