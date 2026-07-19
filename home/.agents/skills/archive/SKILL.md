---
name: archive
description: >-
  使わなくなったファイルを nozomiishii/archives リポジトリに退避する PR を作成する。
  Claude Code で /archive、Codex で $archive と入力したとき、または「アーカイブして」「archives に退避して」と言ったときに使用する。
model: sonnet
---

# /archive

不要になったファイルを `nozomiishii/archives` に退避する PR を作成する。

## 対象ファイルの特定

会話の流れ、または引数からアーカイブ対象を特定する。

- source repo root を `realpath "$(git rev-parse --show-toplevel)"` で確定する。対象は repo root からの相対 path に限定し、絶対 path、空 path、`..` component、control character を拒否する
- tracked file は最初に `git status --porcelain=v1 -- <path>` と `git ls-files -s -- <path>` を確認する。clean な通常ファイルだけ検証済みの index blob または HEAD blob から取得する
- dirty な tracked file は staged、unstaged、削除を区別して差分を提示し、index blob、HEAD blob、worktree のどの版を退避するかユーザーに確認する。選択前に archives へコピーしない。index / HEAD を選んだ場合は検証済み blob を読む。worktree 版を選んだ場合は untracked file と同じ lstat、symlink component、realpath containment の検証後にだけ読む
- mode `120000` の symlink は停止してユーザーに扱いを確認する。link 先を dereference せず、repo 外の実体を読まない。submodule、device、他の特殊 mode も停止する
- untracked file は期待 path と `realpath` が一致し、repo root 内に留まり、symlink component が無い通常ファイルだけ読む
- git で削除済み → 検証済みの相対 path を `git show <ref>:<path>` で取得
- 引数やコンテキストから判断できない → ユーザーに確認

取得後、全ファイルを secret・credential・個人情報について検査する。疑わしい内容があれば archives へコピーする前に停止し、ユーザーに確認する。

## ソース repo の検出

対象ファイルがある repo の名前とオーナーを取得する。

```bash
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)
```

`nozomiishii` 配下なら `<repo>` をディレクトリ名にする。それ以外は `<owner>/<repo>` にする。

ソースが外部 repo、もしくは所有者を判定できない場合は、ファイルの複製・削除・commit・push・PR 作成より先に sibling の [oss SKILL.md](../oss/SKILL.md) を明示的に読み、その承認境界に従う。外部 repo のファイルは secret、個人情報、ライセンスと再配布条件を確認し、archives へ公開可能かをユーザーに確認する。確認前に内容を別 repo へコピーしない。

## archives repo の準備

セッション開始 repo とは別 repo なので、sibling の [wt SKILL.md](../wt/SKILL.md) を明示的に読み、その方針で `nozomiishii/archives` の別 session / task に切り出す。Codex App では archives project の新しい Worktree task、CLI では既存 clone の worktree とバックグラウンド実行を使う。

元の task では、既存 clone の場所をホストの project 一覧または git remote から探して切り出し先を作る。配置場所を `$HOME/Code/...` に固定しない。clone が無い場合はホストの repo 追加機能を使い、利用できなければ clone 先をユーザーに確認する。

切り出し先では cwd が `nozomiishii/archives` の worktree であることを git remote で確認し、`ARCHIVES=$(git rev-parse --show-toplevel)` とする。base clone を再探索しない。branch は wt skill が作成または復元したものをそのまま使う。

最新の main を取得する。worktree 内で main に切り替えない。

```bash
git -C "$ARCHIVES" fetch origin main
```

## 配置ルール

`<repo-dir>/<元のディレクトリ構造>` に配置する。元のパスをそのまま保持し、ファイル名も変えない。

```
archives/
  dotfiles/
    scripts/darwin/claude_insights.sh
    home/Library/LaunchAgents/local.claude-insights.plist
  configs/
    packages/old-plugin/index.ts
  other-owner/other-repo/
    src/legacy.ts
```

配置先に同名ファイルが既にある場合は上書きせず、ユーザーに確認する。

書き込み前に destination の既存 parent component を lstat し、symlink が無いことと、各 parent の `realpath` が `$ARCHIVES` 内に留まることを確認する。final path が symlink または特殊 mode なら上書きせず停止する。source 側で検証した相対 path を文字列連結するだけで destination の安全性を仮定しない。

## ブランチ・コミット・PR

複数ファイルは 1 PR にまとめる。

Claude Code では `chore/archive-${REPO}-<短い説明>`、Codex では `codex/archive-${REPO}-<短い説明>-<task suffix>` を切り出し先のブランチ名にする。wt skill から返された完全な名前を `BRANCH` として保持する。

```bash
git -C "$ARCHIVES" fetch origin main
test "$(git -C "$ARCHIVES" branch --show-current)" = "$BRANCH"
```

ファイルを配置した後:

```bash
git -C "$ARCHIVES" add <配置先パス>
git -C "$ARCHIVES" commit -m "chore: archive <何を> from <repo>"
git -C "$ARCHIVES" push -u origin "$BRANCH"
```

PR 作成。本文は `--body-file` で渡す。

```bash
gh pr create --repo nozomiishii/archives \
  --head "$BRANCH" \
  --title "chore: archive <何を> from <repo>" \
  --body-file <tmpfile>
```

PR 本文に含める情報:
- アーカイブ元の repo とパス
- 背景（削除理由、関連 PR/issue のリンク）。会話から読み取れる範囲で書く

## ソース repo からの削除

archives への PR を作成したら、ソース repo 側でも対象ファイルを削除する PR を作成する。

ソース repo の削除は元の session / task で行う。archives repo 用 task から別 repo を直接変更しない。

```bash
git rm <対象ファイル>
git commit -m "chore: remove <何を>"
git push -u origin <branch>
```

PR 本文には archives 側の PR へのリンクを含める。

両方の PR の URL をまとめて返す。
