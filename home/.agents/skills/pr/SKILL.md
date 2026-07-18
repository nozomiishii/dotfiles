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

## 絶対制約

- マージは実行しない。`gh pr merge` / `gh api .../merge` を呼ばない。マージはユーザーが手動で行う
- PR の状態取得は「状態の収集」の GraphQL 1 ショットに一元化する。`gh pr checks` / `gh pr view --json reviews,...` / `gh api .../comments` を個別に呼ばない。gh が無い cloud セッションは「cloud セッション」の対応表に従う
- force-push は `--force-with-lease` のみ。`--force` は禁止

## cloud セッション

Claude Code on the web などの cloud セッションには gh CLI が無い。`command -v gh` が失敗する環境では、本文の gh 手順を次の対応で読み替える。state file は作らず、ツール結果で判断する。

| 本文の手順 | cloud での手段 |
| --- | --- |
| PR の特定（`gh repo view` / `gh pr view`） | owner / repo は `git remote get-url origin` から取り、PR は `mcp__github__list_pull_requests` の head 指定で引く |
| ブランチ切替（`gh pr checkout`） | `git fetch origin <headRefName> && git checkout <headRefName>` |
| 状態の収集（GraphQL 1 ショット） | `mcp__github__pull_request_read` の get / get_status / get_check_runs / get_review_comments をまとめて呼ぶ。同一 iteration 内で再取得しない |
| CI ログ（`gh run view --log-failed`） | `mcp__github__get_job_logs` |
| thread への返信（GraphQL mutation） | `mcp__github__add_reply_to_pull_request_comment` |
| CI 完了の待ち | 本文の「CI 完了の待ち方」と同じ |

## PR の特定と作業ディレクトリの準備

### 引数の解釈

- `https://github.com/<owner>/<repo>/pull/<N>` 形式の URL: owner / repo / PR 番号を抽出
- `<owner>/<repo>#<N>` 形式: 同上
- 数字だけ: cwd の repo の PR 番号として扱う
- 引数なし: cwd の現在ブランチから検出（`gh pr view --json ...`）

抽出後、`$OWNER` / `$NAME` / `$NUM` を以降の手順で参照する。input 形式ごとの分岐例:

```bash
ARG="$1"  # /pr の引数（無ければ空文字）

if [[ "$ARG" =~ ^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"; NAME="${BASH_REMATCH[2]}"; NUM="${BASH_REMATCH[3]}"
elif [[ "$ARG" =~ ^([^/]+)/([^#]+)#([0-9]+)$ ]]; then
  OWNER="${BASH_REMATCH[1]}"; NAME="${BASH_REMATCH[2]}"; NUM="${BASH_REMATCH[3]}"
elif [[ "$ARG" =~ ^[0-9]+$ ]]; then
  OWNER=$(gh repo view --json owner --jq .owner.login)
  NAME=$(gh repo view --json name --jq .name)
  NUM="$ARG"
else
  # 引数なし: cwd の現在ブランチに紐づく PR を検出
  OWNER=$(gh repo view --json owner --jq .owner.login)
  NAME=$(gh repo view --json name --jq .name)
  NUM=$(gh pr view --json number --jq .number)
fi
```

### 作業ディレクトリの決定

`<owner>/<repo>` が特定できた場合:

1. cwd が既にその repo 内（または worktree 内）なら、そこで作業する
2. そうでなければ `~/Code/<owner>/<repo>` を探す:
   - 存在すればそこに `cd`
   - 無ければ `gh repo clone <owner>/<repo> ~/Code/<owner>/<repo>` でクローンしてから `cd`
3. リモートの最新を取得: `git fetch origin`

引数なしで cwd の現在ブランチから検出する場合は、そのまま cwd で作業する。

### PR のブランチに切り替える

```bash
gh pr checkout <N>
```

`gh pr checkout` は fork からの PR も自動でハンドリングする。

- cwd に未コミットの変更がある場合: ユーザーに状況を伝えて止まる（`git stash` を勝手にしない）
- 既にその PR のブランチにいる場合: そのまま続行

### PR の状態を確認

```bash
gh pr view <N> --json number,url,headRefName,state,mergeStateStatus,mergeable,reviewDecision
```

- PR が見つからない（引数なしのとき）: 「PR が無いので先に `/ta` でブランチを公開する必要がある」と返して止まる。`/ta` を勝手に実行しない。
- `state` が CLOSED / MERGED: その旨を伝えて止まる。

## 状態の収集

GraphQL 1 ショットで PR の完全な state を取得し、temp file (`/tmp/claude-$(id -u)/claude-pr-state-${OWNER}-${NAME}-${NUM}.json`、owner / repo / PR 番号で名前空間を切って並列セッション + 異 repo 同 PR 番号での衝突回避) に保存して以降の判断で再利用する。本 iteration 内では再 fetch しない。

「状態の収集」を実行するタイミング:

- ループ初回
- webhook / `send_later` で再開したとき

```bash
# $OWNER / $NAME / $NUM は「引数の解釈」でセット済み
# TMPDIR は使わない: Claude Code の sandbox は Bash 呼び出しごとに TMPDIR を差し替えることが
# あり、呼び出しをまたぐ state file の再利用が壊れる。uid で名前空間を切った固定パスに置く
STATE_DIR="/tmp/claude-$(id -u)"
mkdir -p -m 700 "$STATE_DIR"
# 他ユーザーが先回りで同名 dir を作る squatting を弾く
[ -O "$STATE_DIR" ] || { echo "ERROR: $STATE_DIR is not owned by me" >&2; exit 1; }
STATE_FILE="$STATE_DIR/claude-pr-state-${OWNER}-${NAME}-${NUM}.json"
# 事前 planted の symlink 経由でリダイレクト先を上書きされる TOCTOU 攻撃を弾く
[ -L "$STATE_FILE" ] && { echo "ERROR: $STATE_FILE is a symlink, refusing to write" >&2; exit 1; }
umask 077  # 他ユーザー read 不可で作成
gh api graphql \
  -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
  -F query=@"$HOME/.agents/skills/pr/state-query.graphql" \
  --jq '.data.repository.pullRequest' > "$STATE_FILE"
```

GraphQL クエリ本体は [home/.agents/skills/pr/state-query.graphql](home/.agents/skills/pr/state-query.graphql) に分離。取得する主な field:

- PR 本体: `state`, `isDraft`, `mergeable`, `mergeStateStatus`, `reviewDecision`, `headRefName`
- CI check: `commits.nodes[0].commit.statusCheckRollup.{state, contexts.nodes[]}` — `CheckRun` には `conclusion`, `databaseId`, `checkSuite.workflowRun.databaseId` まで含む
- レビュー: `reviewThreads.nodes[]` — `isResolved` で確定判定。`comments.nodes[]` に path / line / body / author

state から判断する典型項目:

| 用途 | jq path |
| --- | --- |
| merge 可能性 | `.mergeable`, `.mergeStateStatus`, `.reviewDecision` |
| 失敗 check | `.contexts.nodes[]? \| select(.__typename == "CheckRun" and (.conclusion \| IN("FAILURE","TIMED_OUT","CANCELLED","STARTUP_FAILURE","ACTION_REQUIRED")))` |
| 失敗 run の `databaseId`（→ `gh run view`） | 上の結果から `.checkSuite.workflowRun.databaseId` |
| pending check（polling 判定） | rollup 全体で見るのが正解: `.statusCheckRollup.state` が `EXPECTED` / `PENDING`（個別 `CheckRun.status` を見ると `WAITING` / `REQUESTED` 等のレア値を取りこぼす） |
| 未解決 review thread | `.reviewThreads.nodes[] \| select(.isResolved \| not)` |

旧 3 並列 calls (`gh pr checks` + `gh pr view --json` + `gh api .../comments`) に対する利点:

- 3 calls の間に CI 状態が更新されることで起きる snapshot ズレが消える
- `reviewThreads.isResolved` で「未解決か」が直接取れる（旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定が不要）
- 失敗 run の `databaseId` が直接拾えるので、「CI を直す」の `gh run view` に渡す ID 取得が独立 call なしで済む

境界条件メモ:

- GraphQL の connection cap: `contexts(first: 100)` / `reviewThreads(first: 50)` / `comments(last: 5)`。各 thread の comments は `last: 5` で末尾側を取っているので `nodes[-1]` が確実に「最新コメント」になる（`first: 20` だと 21 件以上の thread で「先頭 20 件の末尾」=「実質的な中央」を最新と誤認する罠があるため）。reviewThreads / contexts の上限を超えるほど長期化した PR が出たら pagination 対応を検討する
- `StatusContext` (legacy CI integrations: Travis, AppVeyor 等) は `__typename` で分岐して失敗判定では無視している（`nozomiishii` 配下は全 GitHub Actions = `CheckRun`）。今後 legacy CI を入れる repo で `/pr` を回す場合はここの再検討が必要
- state file の置き場所: `/tmp/claude-$(id -u)/claude-pr-state-${OWNER}-${NAME}-${NUM}.json`。`$TMPDIR` を使わないのは、Claude Code の sandbox が Bash 呼び出しごとに TMPDIR を差し替えることがあり (呼び出し限りの一時 dir を指す場合、終了時に中身ごと消える)、呼び出しをまたぐ state の再利用というこの skill の前提が壊れるため。共有 `/tmp` 直下に置くので、uid 名前空間の dir を `mkdir -p -m 700` で作り、`-O` の所有者確認で squatting を弾き、書き込み前の symlink check で TOCTOU planted symlink を弾き、`umask 077` で perms 600 にして world-read を防ぐ。残存リスク: symlink check と redirect 間に攻撃者が swap する race window があるが、shell redirect の根源的制約なので mktemp に移行しない限り完全には潰せない（dotfiles ユースケースでは許容範囲と判断）

## 修復（優先度順）

- CI 失敗 — テスト・lint・build・型チェック
- 未対応のレビュー指摘 — actionable なものに限る
- main との conflict / behind

### CI を直す

state file から失敗 run の ID を抽出してログ取得:

```bash
# statusCheckRollup が null（push 直後の race）でも落ちないように nodes[]? を使う。
# failing conclusion は FAILURE 以外にも TIMED_OUT / CANCELLED / STARTUP_FAILURE / ACTION_REQUIRED があり、
# どれも「CI 真っ赤」として扱いたいので whitelist で広く拾う。
jq -r '
  .commits.nodes[0].commit.statusCheckRollup.contexts.nodes[]?
  | select(.__typename == "CheckRun"
           and (.conclusion | IN("FAILURE","TIMED_OUT","CANCELLED","STARTUP_FAILURE","ACTION_REQUIRED")))
  | .checkSuite.workflowRun.databaseId
  | select(. != null)
' "/tmp/claude-$(id -u)/claude-pr-state-${OWNER}-${NAME}-${NUM}.json" | sort -u | while read -r RUN_ID; do
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

### レビュー指摘に対応

state file の `reviewThreads` で `isResolved` が `false` の thread を順に確認する。GraphQL が確定状態を返すので、旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定は不要。

```bash
jq -r '
  .reviewThreads.nodes[]
  | select(.isResolved | not)
  | "[\(.id)] \(.comments.nodes[0].path // "?"):\(.comments.nodes[0].line // 0) — \(.comments.nodes[-1].body | .[0:80])"
' "/tmp/claude-$(id -u)/claude-pr-state-${OWNER}-${NAME}-${NUM}.json"
```

未解決 thread ごとに:

- コード修正依頼: 直して commit → push。push 後、その commit で対応した thread に「thread に返信する」の手順で hash 付き返信を残す
- 質問・確認事項: 同じく thread に返信して回答を残す
- 自分では判断できないもの: ユーザーに「ここ判断ほしい」と渡して止まる
- 自分の最終 reply で実質片付いているが thread が open のまま: そのまま触らない（`isResolved` を flip するのはレビュアー側の仕事）

自分が既に同じ回答を残しているコメントには再投稿しない。

#### thread に返信する

返信は GraphQL mutation `addPullRequestReviewThreadReply` を使う。thread の node id（state file の `reviewThreads.nodes[].id`）をそのまま渡せるので、返信先 comment の databaseId を REST で別途引かずに済む。

```bash
gh api graphql -f query='
  mutation($tid: ID!, $body: String!) {
    addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $tid, body: $body}) {
      comment { url }
    }
  }' -f tid="$THREAD_ID" -f body="$BODY"
```

コード修正への返信は「修正内容を一言 ＋ 短縮 hash」。hash は修正を commit した後に `git rev-parse --short HEAD` で取り、1 commit で複数 thread を直した場合は同じ hash を各 thread に返す。GitHub は本文中の短い SHA を自動でコミットへリンクするので hash はそのまま書けばよい。

返信の言語はレビューコメントに合わせる。state file の当該 thread の comment body に日本語文字（ひらがな・カタカナ・漢字）が含まれれば日本語、なければ英語にする。

- 日本語: `<hash> で <対応内容> を修正しました`
- 英語: `Fixed <what> in <hash>`

### main の進みに追従

`mergeStateStatus` が `BEHIND` / `DIRTY` のとき:

```bash
git fetch origin main
git -C "$(git rev-parse --show-toplevel)" rebase origin/main
# conflict が出たら 1 つずつ解決
git push --force-with-lease
```

worktree でも動くよう `git checkout main` は使わない。

## ループ

### CI 完了の待ち方

push 後、`subscribe_pr_activity` で PR を購読し、`send_later` で再確認を仕込んでからターンを終える。
webhook イベントまたは `send_later` のタイマーで再開し、「状態の収集」で fresh state を取り直して次の iteration に入る。

webhook で届くのはレビューコメントと CI 失敗のみ。CI 成功・新しい push・conflict 発生は届かない。`send_later` の目安は 10 分後、まだ pending なら再アームする。

`subscribe_pr_activity` / `send_later` が承認エラーになる場合は、sleep での polling に落ちず、状況をユーザーに伝えて止まる。

### 抜ける条件

いずれかを満たしたら終了:

- `mergeable: MERGEABLE` かつ `mergeStateStatus` が `CLEAN` / `HAS_HOOKS` / `UNSTABLE`（CI 全 pass）
- 残った課題が「ユーザーの判断が必要なレビュー指摘」のみ
- 同じ修正を 2 回試して同じ失敗が出た（ループ防止）

最大 5 iteration を目安にする。それを超えても抜けられないなら止まって状況をユーザーに渡す。

抜けた時点で、達成状態とユーザー側の next action（マージ可否、残課題）を 3-5 行で報告する。

## 制約

- マージは絶対に実行しない（`gh pr merge` / `gh api .../merge` 禁止）
- 状態取得は「状態の収集」の GraphQL に一元化する: トラブルシューティング中でも `gh pr checks` / `gh pr view --json reviews,statusCheckRollup,...` / `gh api .../comments` を個別に呼ばない。3 calls 間の snapshot ズレと、resolved 判定の REST 推測ミスを避けるため。gh が無い cloud セッションは「cloud セッション」の対応表に従う
- state file は明示削除しない。OS の `/tmp` purge に任せる。セキュリティガードは「状態の収集」に組み込み済み
- PR タイトル / コミットメッセージは英語 Conventional Commits 形式（小文字始まり、ASCII のみ、scope 無し、末尾スペース禁止）
- PR 本文に追記する必要が出た場合は、本文部分は日本語のまま
- `gh pr edit` で本文を更新するときは `--body-file` を使う（HEREDOC で `--body` 直渡しは command injection 検出に引っかかる）
- worktree で動くこと前提（`git checkout main` 禁止、`git fetch origin main && git rebase origin/main` を使う）
- 複合 `cd <path> && git` は使わず `git -C <path>` を使う
- force-push は `--force-with-lease` のみ。`--force` は禁止
- レビュアー判断が必要そうな未解決コメントを勝手に「解決済み」にしない
- main ブランチに直接コミットしない
