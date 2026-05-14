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

並列で取得する:

```bash
gh pr checks <PR>
gh pr view <PR> --json reviews,reviewDecision,mergeStateStatus,mergeable,statusCheckRollup
gh api repos/{owner}/{repo}/pulls/<PR>/comments --jq '.[] | {id, path, line, body, in_reply_to_id}'
```

## 2. 修復（優先度順）

1. **CI 失敗** — テスト・lint・build・型チェック
2. **未対応のレビュー指摘** — actionable なものに限る
3. **main との conflict / behind**

### 2-1. CI を直す

失敗ジョブごとにログを取得:

```bash
gh run view <RUN_ID> --log-failed
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

未解決の review comment（自分の reply で閉じていないもの）を順に確認:

- コード修正依頼: 直して commit & push
- 質問・確認事項: GitHub 上で回答 comment を残す（`gh pr comment` または `gh api .../comments/<id>/replies`）
- 自分では判断できないもの: ユーザーに「ここ判断ほしい」と渡して止まる
- 既に対応済みっぽいもの: 触らない

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

push の後は CI が走り直すので、step 1 に戻って status を再取得する。

### CI 完了の待ち方

push 直後は workflow がまだ queue されていない。`gh pr checks <PR>` を経験データベースの段階的 backoff で polling する。固定 20s だと長時間 workflow（例: `nozomiishii/dotfiles` の CI）で polling 回数が爆発する。

**`gh pr checks --watch` は使わない**: workflow 全体が path-filter / `if:` 条件で skip された場合に `skipping` ステータスで残り、gh CLI が terminal と認識せず無限ループする（README 変更のみの PR で `actionlint` / `zizmor` などが path-filter で skip されるケース等）。

polling 例:

```bash
intervals=(5 5 10 10 15 30 60 90 120)
deadline=$(( $(date +%s) + 60 * 60 ))
i=0
while gh pr checks <PR> 2>/dev/null | awk '{print $2}' | grep -qE '^(pending|queued|in_progress)$'; do
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "CI polling exceeded 60 min" >&2
    break
  fi
  idx=$(( i < ${#intervals[@]} ? i : ${#intervals[@]} - 1 ))
  sleep "${intervals[$idx]}"
  i=$((i + 1))
done
```

スケジュール根拠（`nozomiishii` 配下 13 repo / 409 runs の duration 分析）:

- 全 run p50=20s / p75=33s / p90=2.0m → 5–15s 刻みで p75 帯は 3 poll 以内に検知できる
- `nozomiishii/dotfiles` の CI は outlier (p50=18.8m / max=45.1m) → cap 120s と 60 min timeout で吸収
- 固定 20s と比較して 30 分待ちで polling 90 calls → ~25 calls（約 1/3）

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
