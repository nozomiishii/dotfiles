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

抽出後、`$OWNER` / `$NAME` / `$NUM` を後続 section で参照する。input 形式ごとの分岐例:

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

GraphQL 1 ショットで PR の完全な state を取得し、temp file (`${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json`、owner / repo / PR 番号で名前空間を切って並列セッション + 異 repo 同 PR 番号での衝突回避) に保存して以降の判断で再利用する。本 iteration 内では再 fetch しない。

**section 1 を実行するタイミング**:

- ループ初回（最初の state 取得）
- 直前 iter で push を行わず polling も走らなかったとき（例: section 2-2 のレビュー回答 comment だけで終わった iter）。レビュアー側で thread が解決された可能性があるので fresh state を取り直す
- それ以外（直前 iter で push → polling した）は **section 3 polling 終了時の最終 state がそのまま次 iter の入力**になるので、section 1 はスキップ

```bash
# $OWNER / $NAME / $NUM は section 0-1 でセット済み
STATE_FILE="${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json"
# 事前 planted の symlink 経由でリダイレクト先を上書きされる TOCTOU 攻撃を弾く
[ -L "$STATE_FILE" ] && { echo "ERROR: $STATE_FILE is a symlink, refusing to write" >&2; exit 1; }
umask 077  # 他ユーザー read 不可で作成（/tmp 直叩きフォールバック時の保険）
gh api graphql \
  -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
  -F query=@"$HOME/.claude/skills/pr/state-query.graphql" \
  --jq '.data.repository.pullRequest' > "$STATE_FILE"
```

GraphQL クエリ本体は [home/.claude/skills/pr/state-query.graphql](home/.claude/skills/pr/state-query.graphql) に分離。取得する主な field:

- PR 本体: `state`, `isDraft`, `mergeable`, `mergeStateStatus`, `reviewDecision`, `headRefName`
- CI check: `commits.nodes[0].commit.statusCheckRollup.{state, contexts.nodes[]}` — `CheckRun` には `conclusion`, `databaseId`, `checkSuite.workflowRun.databaseId` まで含む
- レビュー: `reviewThreads.nodes[]` — `isResolved` で確定判定。`comments.nodes[]` に path / line / body / author

state から判断する典型項目:

| 用途 | jq path |
|---|---|
| merge 可能性 | `.mergeable`, `.mergeStateStatus`, `.reviewDecision` |
| 失敗 check | `.contexts.nodes[]? \| select(.__typename == "CheckRun" and (.conclusion \| IN("FAILURE","TIMED_OUT","CANCELLED","STARTUP_FAILURE","ACTION_REQUIRED")))` |
| 失敗 run の `databaseId`（→ `gh run view`） | 上の結果から `.checkSuite.workflowRun.databaseId` |
| pending check（polling 判定） | rollup 全体で見るのが正解: `.statusCheckRollup.state` が `EXPECTED` / `PENDING`（個別 `CheckRun.status` を見ると `WAITING` / `REQUESTED` 等のレア値を取りこぼす） |
| 未解決 review thread | `.reviewThreads.nodes[] \| select(.isResolved \| not)` |

旧 3 並列 calls (`gh pr checks` + `gh pr view --json` + `gh api .../comments`) に対する利点:

- 3 calls の間に CI 状態が更新されることで起きる snapshot ズレが消える
- `reviewThreads.isResolved` で「未解決か」が直接取れる（旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定が不要）
- 失敗 run の `databaseId` が直接拾えるので、section 2-1 の `gh run view` に渡す ID 取得が独立 call なしで済む

境界条件メモ:

- **GraphQL の connection cap**: `contexts(first: 100)` / `reviewThreads(first: 50)` / `comments(last: 5)`。各 thread の comments は `last: 5` で末尾側を取っているので `nodes[-1]` が確実に「最新コメント」になる（`first: 20` だと 21 件以上の thread で「先頭 20 件の末尾」=「実質的な中央」を最新と誤認する罠があるため）。reviewThreads / contexts の上限を超えるほど長期化した PR が出たら pagination 対応を検討する
- **`StatusContext` (legacy CI integrations: Travis, AppVeyor 等)** は `__typename` で分岐して **失敗判定では無視**している（`nozomiishii` 配下は全 GitHub Actions = `CheckRun`）。今後 legacy CI を入れる repo で `/pr` を回す場合はここの再検討が必要
- **state file の置き場所**: `${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json`。macOS では `$TMPDIR` が user-private な `/var/folders/<user>/.../T/` を指すので他ユーザーから読めない。Linux / WSL で `$TMPDIR` 未設定 → `/tmp` フォールバックの場合に備えて、書き込み前に **symlink check** で TOCTOU planted symlink を弾き、`umask 077` で perms 600 にして world-read を防ぐ。残存リスク: symlink check と redirect 間に共有 `/tmp` で攻撃者が swap する race window があるが、shell redirect の根源的制約なので mktemp に移行しない限り完全には潰せない（dotfiles ユースケースでは許容範囲と判断）

## 2. 修復（優先度順）

1. **CI 失敗** — テスト・lint・build・型チェック
2. **未対応のレビュー指摘** — actionable なものに限る
3. **main との conflict / behind**

### 2-1. CI を直す

`${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json` から失敗 run の ID を抽出してログ取得:

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
' ${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json | sort -u | while read -r RUN_ID; do
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

`${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json` の `reviewThreads` で **`isResolved = false`** の thread を順に確認する。GraphQL が確定状態を返すので、旧 REST `comments` + `in_reply_to_id` chain を辿る推測判定は不要。

```bash
jq -r '
  .reviewThreads.nodes[]
  | select(.isResolved | not)
  | "[\(.id)] \(.comments.nodes[0].path // "?"):\(.comments.nodes[0].line // 0) — \(.comments.nodes[-1].body | .[0:80])"
' ${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json
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

push の後は CI が走り直すので、graphql で state を取り直して `${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json` を更新する。**polling 終了時の最終 state がそのまま次 iter の入力**になるので、section 1 で再取得しない。

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
  local f="${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json"
  [ -L "$f" ] && { echo "ERROR: $f is a symlink, refusing to write" >&2; return 1; }
  umask 077
  gh api graphql \
    -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
    -F query=@"$HOME/.claude/skills/pr/state-query.graphql" \
    --jq '.data.repository.pullRequest' > "$f"
}

refresh_state
# "まだ待つべき" 条件:
#   - rollup 未生成 (push 直後で check が登録されていない)
#   - rollup state が EXPECTED / PENDING
#   - mergeable が UNKNOWN (GitHub 側がまだ mergeable を計算中)
# rollup null チェックを入れないと check 未登録時に loop を抜けて誤完了判定する。
# mergeable UNKNOWN を待つのは「抜ける条件」が mergeable: MERGEABLE を要求するため。
while jq -e '
  .commits.nodes[0].commit.statusCheckRollup as $r
  | ($r == null)
    or ($r.state == "EXPECTED") or ($r.state == "PENDING")
    or (.mergeable == "UNKNOWN")
' ${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json >/dev/null 2>&1; do
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
# loop 抜け後の ${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json が次 iter の入力（section 1 で再取得しない）
```

旧実装で警戒していた `gh pr checks --watch` 無限ループ問題（path-filter で skip された workflow を gh CLI が terminal と認識しないやつ）は、本実装が `statusCheckRollup.state` を直接見るので回避される。skip された workflow run は check が作られず rollup の集計対象から外れ、skip された個別 job は `conclusion: SKIPPED` で `COMPLETED` 扱いになるので、rollup state は最終的に `SUCCESS` / `FAILURE` / `ERROR` のいずれかに確実に落ちる。

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
- **状態取得は section 1 の GraphQL に一元化する**: トラブルシューティング中でも `gh pr checks` / `gh pr view --json reviews,statusCheckRollup,...` / `gh api .../comments` を個別に呼ばない。3 calls 間の snapshot ズレと、resolved 判定の REST 推測ミスを避けるため
- **state file (`${TMPDIR:-/tmp}/claude-pr-state-${OWNER}-${NAME}-${NUM}.json`) は明示削除しない**: OS の `/tmp` 定期 purge に任せる。skill 終了時に `rm` を仕込まないことで、直後の手動デバッグ（`jq ... "${TMPDIR:-/tmp}/claude-pr-state-<OWNER>-<NAME>-<NUM>.json"` で覗く）の利便性を維持する。書き込み側のセキュリティガード（symlink check + `umask 077`）は section 1 と `refresh_state` に組み込み済みなので、`/tmp` フォールバック環境でも TOCTOU planted symlink と world-read の主要経路は塞がれる
- PR タイトル / コミットメッセージは英語 Conventional Commits 形式（小文字始まり、ASCII のみ、scope 無し、末尾スペース禁止）
- PR 本文に追記する必要が出た場合は、本文部分は日本語のまま
- `gh pr edit` で本文を更新するときは `--body-file` を使う（HEREDOC で `--body` 直渡しは command injection 検出に引っかかる）
- worktree で動くこと前提（`git checkout main` 禁止、`git fetch origin main && git rebase origin/main` を使う）
- 複合 `cd <path> && git` は使わず `git -C <path>` を使う
- force-push は `--force-with-lease` のみ。`--force` は禁止
- レビュアー判断が必要そうな未解決コメントを勝手に「解決済み」にしない
- main ブランチに直接コミットしない
