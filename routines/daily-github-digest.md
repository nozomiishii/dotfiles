---
name: daily-github-digest
schedule: "Every day at 05:07 (JST)"
triggers: [schedule]
repos: [nozomiishii/dotfiles]
labels: [github-digest-daily]
---

# daily-github-digest

過去 24 時間の GitHub 通知から以下を抽出し、日本語要約 issue を `nozomiishii/dotfiles` に投稿する。

1. **自分の管理外プロダクトの release**: 新機能・破壊的変更・主要 fix を解説
2. **自分の repo への Renovate PR**: パッケージ・version・変更点を解説

両カテゴリ合計 0 件なら issue を作らずに終了する（ノイズ防止）。

設計の経緯: [nozomiishii/dotfiles#946](https://github.com/nozomiishii/dotfiles/issues/946)。

---

## 0. 前提

- 実行環境は Claude Code cloud session（Linux）。`gh` は user identity で認証済み。
- repo は `nozomiishii/dotfiles` の default branch (`main`) が clone 済み。
- issue 作成のみ行い、`claude/*` 以外のブランチへの push は行わない（default permission のままで動作する）。

---

## 1. 通知取得

実行時刻から 24 時間前を ISO 8601 UTC で計算し、`/notifications` を全件取得する。

```bash
SINCE=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
gh api "/notifications?all=true&since=$SINCE&per_page=100" --paginate > /tmp/notifs.json
```

`gh api` が 401 / 403 で落ちる場合は `gh` の OAuth scope が不足している可能性。session 末尾に「auth scope 不足のため取得できなかった」とログを残して終了する（issue は作らない）。

---

## 2. フィルタ

`/tmp/notifs.json` に対し以下のロジックを適用する。

### 2-A. Release（管理外プロダクト）

抽出条件:

- `subject.type == "Release"`
- `repository.owner.login != "nozomiishii"`

各エントリで `subject.url` を `gh api` に渡して release notes を取得する:

```bash
gh api "$RELEASE_URL" \
  --jq '{repo: .url, repo_full: env.REPO_FULL, tag: .tag_name, name: .name, body: .body, html_url: .html_url, published_at: .published_at, prerelease: .prerelease}'
```

同一 release への通知が複数あれば `html_url` で dedup する。

### 2-B. Renovate PR（自分の repo）

抽出条件:

- `subject.type == "PullRequest"`
- `repository.owner.login == "nozomiishii"`

PR の詳細を取得し、author が `renovate[bot]` であるものだけ残す:

```bash
gh pr view "$PR_NUMBER" -R "$OWNER/$REPO" \
  --json author,title,body,url,state,headRefName,baseRefName,files
```

条件:

- `author.login == "renovate[bot]"` 以外は捨てる
- 同一 PR への通知が複数あれば `url` で dedup
- PR の state（open / merged / closed）は問わず、24h 内に通知が来ているもの全部を対象にする

---

## 3. 日本語要約

### Release

各 release について以下を 3〜5 行で日本語要約する。重要度に応じて行数を調整する:

- 何のプロダクトか（必要なら 1 行で補足）
- 新機能（注目すべき機能追加）
- 破壊的変更（あれば必ず明示）
- 主要な fix / 改善

依存更新のみの小さな patch なら 1〜2 行で簡潔に。release notes が空の場合は「release notes 無し（tag のみ）」と書く。

### Renovate PR

各 PR について以下を 1〜3 行で日本語要約する:

- 対象パッケージと version 範囲（`<old> → <new>`）
- パッケージの役割（必要なら）
- 変更の意味（major / minor / patch、破壊的変更の有無、注目変更点）

手がかりは PR title（例: `chore(deps): update dependency <pkg> to v<x>`）と PR body（Renovate が貼る Release Notes セクション / Configuration セクション）。body から重要部分だけ拾う。

---

## 4. issue 本文の組み立て

以下フォーマットで markdown を組み立てる。

```markdown
過去 24 時間 (since <SINCE>) の GitHub 通知から抽出。

## 自分の管理外プロダクトのリリース

### [<owner>/<repo>](<repo-html-url>) — <tag>

<日本語要約 3〜5 行>

- Release: <release-html-url>

### [<owner2>/<repo2>](<repo-html-url2>) — <tag2>

...

## 自分のリポジトリへの Renovate アップデート

### [<owner>/<repo>](<repo-html-url>) — <package> <old> → <new>

<日本語要約 1〜3 行>

- PR: <pr-html-url>

...
```

注意:

- どちらかのセクションが 0 件なら、その `## ...` 見出しごと省略する
- repo link は `https://github.com/<owner>/<repo>`
- 並び順は `published_at` / PR の `updatedAt` の降順（新しいものが上）

---

## 5. issue 作成

合計 0 件なら **issue を作らずに終了**。session 末尾に「過去 24h に対象通知なし」と一言ログを残す。

0 件超なら issue を作成する。

```bash
TITLE="chore: daily digest $(TZ=Asia/Tokyo date +%Y-%m-%d) (jst)"
BODY_FILE=$(mktemp)
# 上で組み立てた markdown を $BODY_FILE に書く
gh issue create -R nozomiishii/dotfiles \
  --title "$TITLE" \
  --label github-digest-daily \
  --body-file "$BODY_FILE"
```

ポイント:

- title は Conventional Commits 形式（英語・小文字・scope なし）。type は `chore`
- `gh issue create` は `--body-file` を使う（`--body` 直渡しは command injection 検出に引っかかる）
- label `github-digest-daily` が存在しない場合は事前に作る:
  ```bash
  gh label create github-digest-daily \
    -R nozomiishii/dotfiles \
    -c "#1d76db" \
    -d "Daily GitHub notifications digest" \
    --force
  ```
  `--force` で既存なら no-op。

---

## 6. 完了ログ

session 末尾に以下のどれかを 1 行出力して終了する:

- issue を作った場合: 作成した issue の URL
- 0 件で終了した場合: `過去 24h に対象通知なし`
- auth エラー等で落ちた場合: 原因と次のアクション
