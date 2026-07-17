---
name: broadcast
description: >-
  projects.json で管理されている複数の独立 repo に、同じ変更を横断適用（broadcast）する。
  ユーザーが /broadcast と入力したとき、または「workspaces のプロジェクト全部に〜したい」「横断で〜入れたい」と言ったときに使用する。
  第 1 引数が既存ディレクトリならその配下の projects.json を、それ以外は ~/Code/nozomiishii/workspaces/projects.json を対象にする。
  公式 bundled の /batch（1 つの repo を 5-30 ユニットに分解して worktree 並列実行）とは別物。こちらは N 個の repo への同一変更 broadcast。
---

# /broadcast

projects.json に列挙された `enabled: true` の全プロジェクト（それぞれ独立した repo）に対し、同じ変更（CODEOWNERS 追加、workflow 更新、設定ファイルの一括同期、依存パッケージのバージョン揃え、など）を横断で broadcast する。

> 公式 `/batch` との違い: bundled の `/batch` は 1 つの codebase を 5-30 の独立ユニットに分解して各々を git worktree で並列実装する。`/broadcast` は複数の別 repo に同一の変更を撒く。対象も粒度も別物。

ユーザーが `/broadcast` を実行した時点で、横断変更の依頼とみなす。

## 引数

```
/broadcast [<projects-json-dir>] <変更内容の指示...>
```

- 第 1 引数が既存ディレクトリ → そこを `<projects-json-dir>` として `<dir>/projects.json` を読む
- 第 1 引数がディレクトリでない → 全引数を指示として扱い、`<projects-json-dir>` は `~/Code/nozomiishii/workspaces` をデフォルトにする
- 指示部分が空のとき → ユーザーに「何を適用するか」を聞いて止まる（projects.json の一覧だけ読み込んで提示してよい）

## projects.json を読む

```bash
PROJECTS_JSON="${PROJECTS_JSON_DIR:-$HOME/Code/nozomiishii/workspaces}/projects.json"
jq -r '.[] | select(.enabled == true) | "\(.name)\t\(.rootPath)"' "$PROJECTS_JSON"
```

- `enabled: false` は対象外
- `rootPath` の `~` は `$HOME` に展開する（`jq` 後に shell or 自前で展開）
- projects.json が無い cloud セッションでは、add_repo で nozomiishii/workspaces をセッションに追加し、clone された projects.json を読む

## 対象リストを提示する

実行前に、対象候補と適用予定の変更内容をユーザーに見せる。形式は表でよい:

```
| name          | rootPath                              | 対象ファイル有無 |
|---------------|---------------------------------------|------------------|
| 🧙🏿‍♂️ dotfiles | ~/Code/nozomiishii/dotfiles           | あり             |
| 🪴 brain      | ~/Code/nozomiishii/brain              | なし             |
| 🛰️ infra      | ~/Code/nozomiishii/infra              | あり             |
| ...           | ...                                   | ...              |
```

- 「対象ファイル有無」は変更内容に応じて事前 check した結果（例: CODEOWNERS 更新なら `.github/CODEOWNERS` の存在、workflow なら `.github/workflows/<name>.yaml` など）
- 対象ファイルが無いプロジェクトは「新規作成するか / スキップするか」をユーザーに判断してもらう
- ユーザーが OK を出したら次に進む

## 各プロジェクトで変更を適用する

プロジェクト数と変更の複雑さに応じて選ぶ:

- 数件 or 変更が単純（1 ファイル sed 相当）: foreground で順に処理。`git -C <rootPath>` で操作する
- 多数 or 変更にコンテキスト判断が要る（コミットメッセージ自動生成、conflict 解消、新規ファイル雛形作成など）: Agent tool で各プロジェクトを別 Agent に dispatch する
- rootPath が無い cloud セッションでは、`~/Code/<owner>/<repo>` の規約から owner/repo を導出して add_repo し、clone 先を rootPath として扱う

各プロジェクトで実行する典型ステップ:

- `git -C <rootPath> status --short` で clean か確認（dirty なら本人に判断を委ねる）
- ブランチを切る: `git -C <rootPath> fetch origin main && git -C <rootPath> checkout -b <branch> origin/main`
- 変更を適用する
- commit & push（コミットメッセージは各 repo の commitlint ルールに従う）
- ユーザーが PR まで欲しいと言った場合のみ、push 済みブランチから PR を作成する。本文は日本語で `--body-file` 渡し: `gh pr create --repo <owner>/<repo> --head <branch> --title "<type>: <subject>" --body-file <tmpfile>`
- gh が無い cloud セッションでは、PR は GitHub MCP の create_pull_request で作る

## 結果を報告する

完了時に以下を 1 表で出す:

```
| name          | 結果        | 詳細                       |
|---------------|-------------|----------------------------|
| 🧙🏿‍♂️ dotfiles | ✅ commit済 | branch: chore/add-foo      |
| 🪴 brain      | ⏭ skip      | 対象ファイル無し           |
| 🛰️ infra      | ⚠ 要判断    | git dirty, 本人確認        |
| ...           | ...         | ...                        |
```

「変更したプロジェクト」「スキップしたプロジェクト」「ユーザー判断が必要なプロジェクト」を明確に分けて報告する。

## 制約

- `projects.json` を編集しないこと。skill の責務は projects.json を「読む」ことだけで、プロジェクト一覧の追加/削除はユーザーが手で `~/Code/nozomiishii/workspaces` を編集する
- PR のマージは絶対に実行しない（`/ta`・`/pr` skill の制約と同じ）
- git 操作は `cd <path> && git` でなく `git -C <path>` を使う（bare repository attack 防止の sandbox 制約）
- worktree でも動くよう `git checkout main` は使わず `git fetch origin main && git checkout -b <branch> origin/main` を使う
- 変更内容が repo によって意味的に違う場合（例: 各 repo の独自命名規則が絡む）は、ユーザーに「同じ変更でいいか / repo ごとに差分があるか」を確認してから進める
- cloud セッションでは /broadcast の依頼を、必要な repo を add_repo で追加する明示的な依頼として扱う。承認プロンプトが出たらユーザーの承認を待ち、repo が揃うまで先の手順に進まない
