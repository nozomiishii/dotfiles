---
name: pr
description: >-
  現在のブランチに紐づく PR の CI 失敗・レビュー指摘・main との conflict を修復し、
  mergeable な状態まで持っていく。ユーザーが /pr と入力したときに使用する。
---

# /pr

pr — Pull Request 当番。CI が落ちていたり、main が進んでいたり、レビューが残っている PR を、mergeable まで連れていく。マージは絶対にしない（ユーザーが手動マージ）。

ユーザーが `/pr` を実行した時点で、PR の修復依頼とみなす。引数で PR 番号 / URL が渡された場合はそれを対象にする。引数が無ければ現在ブランチから検出する。

新しいセッションで `/pr <URL>` だけが渡される場合もある。その場合は cwd や git repo の状態を仮定せず、URL から自分で作業ディレクトリを準備すること。

## 0. PR の特定と作業ディレクトリの準備

### 0-1. 引数の解釈

- `https://github.com/<owner>/<repo>/pull/<N>` 形式の URL: owner / repo / PR 番号を抽出
- `<owner>/<repo>#<N>` 形式: 同上
- 数字だけ: cwd の repo の PR 番号として扱う
- 引数なし: cwd の現在ブランチから検出（`gh pr view --json ...`）

### 0-2. 作業ディレクトリの決定

`<owner>/<repo>` が特定できた場合:

1. cwd が既にその repo 内（または worktree 内）なら、そこで作業する
2. そうでなければ `~/Code/<owner>/<repo>` を探す:
   - 存在すればそこに `cd`
   - 無ければ `gh repo clone <owner>/<repo> ~/Code/<owner>/<repo>` でクローンしてから `cd`
3. リモートの最新を取得: `git fetch origin`

引数なしで cwd の現在ブランチから検出する場合は、そのまま cwd で作業する。

### 0-3. PR のブランチに切り替える

```bash
gh pr checkout <N>
```

`gh pr checkout` は fork からの PR も自動でハンドリングする。

- cwd に未コミットの変更がある場合: ユーザーに状況を伝えて止まる（`git stash` を勝手にしない）
- 既にその PR のブランチにいる場合: そのまま続行

### 0-4. PR の状態を確認

```bash
gh pr view <N> --json number,url,headRefName,state,mergeStateStatus,mergeable,reviewDecision
```

- PR が見つからない（引数なしのとき）: 「PR が無いので先に `/ta` でブランチを公開する必要がある」と返して止まる。`/ta` を勝手に実行しない。
- `state` が CLOSED / MERGED: その旨を伝えて止まる。

## 1. 状態の収集

GraphQL 1 ショットで PR の完全な state を取得し、temp file (`/tmp/claude-pr-state.json`) に保存して以降の判断で再利用する。本 iteration 内では再 fetch しない。section 3 の polling 終了時の最終 state がそのまま次 iter の入力になるので、section 1 はループ初回のみ動かす。

```bash
# section 0 で抽出した owner / repo / PR 番号を env として使う
export OWNER=<owner> NAME=<repo> NUM=<N>

gh api graphql \
  -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
  -F query=@"$HOME/.claude/skills/pr/state-query.graphql" \
  --jq '.data.repository.pullRequest' > /tmp/claude-pr-state.json
```

GraphQL クエリ本体は [home/.claude/skills/pr/state-query.graphql](home/.claude/skills/pr/state-query.graphql) に分離。取得する主な field:

- PR 本体: `state`, `isDraft`, `mergeable`, `mergeStateStatus`, `reviewDecision`, `headRefName`
- CI check: `commits.nodes[0].commit.statusCheckRollup.{state, contexts.nodes[]}` — `CheckRun` には `conclusion`, `databaseId`, `checkSuite.workflowRun.databaseId` まで含む
- レビュー: `reviewThreads.nodes[]` — `isResolved` で確定判定。`comments.nodes[]` に path / line / body / author

state から判断する典型項目:

| 用途 | jq path |
|---|---|
| merge 可能性 | `.mergeable`, `.mergeStateStatus`, `.reviewDecision` |
| 失敗 check | `.commits.nodes[0].commit.statusCheckRollup.contexts.nodes[] \| select(.__typename == "CheckRun" and .conclusion == "FAILURE")` |
| 失敗 run の `databaseId`（→ `gh run view`） | 上の結果から `.checkSuite.workflowRun.databaseId` |
| pending check（polling 判定） | `.contexts.nodes[] \| select(.__typename == "CheckRun" and (.status == "QUEUED" or .status == "IN_PROGRESS"))` |
| 未解決 review thread | `.reviewThreads.nodes[] \| select(.isResolved \| not)` |

旧 3 並列 calls (`gh pr checks` + `gh pr view --json` + `gh api .../comments`) に対する利点:

- 3 calls の間に CI 状態が更新されることで起きる snapshot ズレが消える
- `reviewThreads.isResolved` で「未解決か」が直接取れる（旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定が不要）
- 失敗 run の `databaseId` が直接拾えるので、section 2-1 の `gh run view` に渡す ID 取得が独立 call なしで済む

## 2. 修復（優先度順）

1. **CI 失敗** — テスト・lint・build・型チェック
2. **未対応のレビュー指摘** — actionable なものに限る
3. **main との conflict / behind**

### 2-1. CI を直す

`/tmp/claude-pr-state.json` から失敗 run の ID を抽出してログ取得:

```bash
jq -r '
  .commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]
  | select(.__typename == "CheckRun" and .conclusion == "FAILURE")
  | .checkSuite.workflowRun.databaseId
' /tmp/claude-pr-state.json | sort -u | while read -r RUN_ID; do
  gh run view "$RUN_ID" --log-failed
done
```

ログを読み、原因に応じて修正する:

- テスト失敗: 期待値か実装かを判断して直す
- lint 失敗: 指摘どおりに修正（可能ならフォーマッタを走らせる）
- build 失敗: エラーメッセージから当該箇所を直す
- 型エラー: 該当ファイルを直す

修正後 commit & push:

```bash
git add <files>
git commit -m "fix: <英語小文字始まりで何を直したか>"
git push
```

コミットメッセージはリポジトリの commitlint ルールに従う（Conventional Commits / 英語 / 小文字始まり / ASCII のみ）。

### 2-2. レビュー指摘に対応

`/tmp/claude-pr-state.json` の `reviewThreads` で **`isResolved = false`** の thread を順に確認する。GraphQL が確定状態を返すので、旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定は不要。

```bash
jq -r '
  .reviewThreads.nodes[]
  | select(.isResolved | not)
  | "[\(.id)] \(.comments.nodes[0].path // "?"):\(.comments.nodes[0].line // 0) — \(.comments.nodes[-1].body | .[0:80])"
' /tmp/claude-pr-state.json
```

未解決 thread ごとに:

- コード修正依頼: 直して commit & push
- 質問・確認事項: GitHub 上で回答 comment を残す（`gh pr comment` または `gh api .../comments/<id>/replies`）
- 自分では判断できないもの: ユーザーに「ここ判断ほしい」と渡して止まる
- 自分の最終 reply で実質片付いているが thread が open のまま: そのまま触らない（`isResolved` を flip するのはレビュアー側の仕事）

自分が既に同じ回答を残しているコメントには再投稿しない。

### 2-3. main の進みに追従

`mergeStateStatus` が `BEHIND` / `DIRTY` のとき:

```bash
git fetch origin main
git -C "$(git rev-parse --show-toplevel)" rebase origin/main
# conflict が出たら 1 つずつ解決
git push --force-with-lease
```

worktree でも動くよう `git checkout main` は使わない。

## 3. ループ

push の後は CI が走り直すので、graphql で state を取り直して `/tmp/claude-pr-state.json` を更新する。**polling 終了時の最終 state がそのまま次 iter の入力**になるので、section 1 で再取得しない。

### CI 完了の待ち方

push 直後は workflow がまだ queue されていない。state を 2 段階 backoff で polling する。固定 20s だと長時間 workflow（例: `nozomiishii/dotfiles` の CI）で polling 回数が爆発する。

polling 例:

```bash
# 初回 5s で素早く確認 → ~10 分まで 60s 間隔 → それ以降は 300s 間隔
# nozomiishii 配下を実測すると 98 job 中 56% が timeout-minutes:10 のため、10 分で粒度を切り替える
intervals=(5 60 60 60 60 60 60 60 60 60 60)
deadline=$(( $(date +%s) + 60 * 60 ))
i=0

refresh_state() {
  gh api graphql \
    -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
    -F query=@"$HOME/.claude/skills/pr/state-query.graphql" \
    --jq '.data.repository.pullRequest' > /tmp/claude-pr-state.json
}

refresh_state
while jq -e '
  .commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]
  | select(.__typename == "CheckRun" and (.status == "QUEUED" or .status == "IN_PROGRESS"))
' /tmp/claude-pr-state.json >/dev/null 2>&1; do
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "CI polling exceeded 60 min" >&2
    break
  fi
  if [ "$i" -lt ${#intervals[@]} ]; then
    sleep "${intervals[$i]}"
  else
    sleep 300
  fi
  i=$((i + 1))
  refresh_state
done
# loop 抜け後の /tmp/claude-pr-state.json が次 iter の入力（section 1 で再取得しない）
```

旧実装で警戒していた `gh pr checks --watch` 無限ループ問題（path-filter で skip された workflow が `skipping` ステータスで残り gh CLI が terminal と認識しないやつ）は、GraphQL ベースで CheckRun の `status` を直接見るようになったので回避される（`status` は `QUEUED` / `IN_PROGRESS` / `COMPLETED` の 3 値で、skip は `COMPLETED` 扱い）。

スケジュール根拠:

- `nozomiishii` 配下の workflow を実測すると 98 job のうち 92% が `timeout-minutes` 設定済み。そのうち **10 分が 56%**（次点 5 分 27%、1 分 11%、上位 3 値で 94%）。10 分が dominant なのは reusable workflow（`actionlint` / `zizmor` / `secretlint` / `release-please`）が各 repo に広く展開されているため
- → 10 分までは 1 分粒度で十分、10 分超は outlier 扱いで 5 分粒度に落として polling 回数を抑える
- 一方 `nozomiishii/dotfiles` の `ci.yaml install` は **40 分** の outlier（Brewfile / toolchain セットアップを fan-out）。60 min hard timeout で吸収
- 固定 20s 比で 30 分待ちが ~90 calls → ~16 calls（約 1/6）

### 抜ける条件

いずれかを満たしたら終了:

- `mergeable: MERGEABLE` かつ `mergeStateStatus` が `CLEAN` / `HAS_HOOKS` / `UNSTABLE`（CI 全 pass）
- 残った課題が「ユーザーの判断が必要なレビュー指摘」のみ
- 同じ修正を 2 回試して同じ失敗が出た（ループ防止）

最大 5 iteration を目安にする。それを超えても抜けられないなら止まって状況をユーザーに渡す。

抜けた時点で、達成状態とユーザー側の next action（マージ可否、残課題）を 3-5 行で報告する。

## 制約

- **マージは絶対に実行しない**（`gh pr merge` / `gh api .../merge` 禁止）
- PR タイトル / コミットメッセージは英語 Conventional Commits 形式（小文字始まり、ASCII のみ、scope 無し、末尾スペース禁止）
- PR 本文に追記する必要が出た場合は、本文部分は日本語のまま
- `gh pr edit` で本文を更新するときは `--body-file` を使う（HEREDOC で `--body` 直渡しは command injection 検出に引っかかる）
- worktree で動くこと前提（`git checkout main` 禁止、`git fetch origin main && git rebase origin/main` を使う）
- 複合 `cd <path> && git` は使わず `git -C <path>` を使う
- force-push は `--force-with-lease` のみ。`--force` は禁止
- レビュアー判断が必要そうな未解決コメントを勝手に「解決済み」にしない
- main ブランチに直接コミットしない
