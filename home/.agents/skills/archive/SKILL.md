---
name: archive
description: >-
  使わなくなったファイルを nozomiishii/archives リポジトリに退避する PR を作成する。
  ユーザーが /archive と入力したとき、または「アーカイブして」「archives に退避して」と言ったときに使用する。
model: sonnet
---

# /archive

不要になったファイルを `nozomiishii/archives` に退避する PR を作成する。

## 対象ファイルの特定

会話の流れ、または引数からアーカイブ対象を特定する。

- ワーキングツリーに存在するファイル → そのまま読む
- git で削除済み → `git show <ref>:<path>` で内容を取得
- 引数やコンテキストから判断できない → ユーザーに確認

## ソース repo の検出

対象ファイルがある repo の名前とオーナーを取得する。

```bash
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)
```

`nozomiishii` 配下なら `<repo>` をディレクトリ名にする。それ以外は `<owner>/<repo>` にする。

## archives repo の準備

```bash
ARCHIVES="$HOME/Code/nozomiishii/archives"
```

ローカルに存在しなければ clone する。

```bash
if [[ ! -d "$ARCHIVES" ]]; then
  gh repo clone nozomiishii/archives "$ARCHIVES"
fi
```

最新の main を取得する。

```bash
git -C "$ARCHIVES" checkout main
git -C "$ARCHIVES" pull origin main
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

## ブランチ・コミット・PR

複数ファイルは 1 PR にまとめる。

```bash
BRANCH="chore/archive-${REPO}-<短い説明>"
git -C "$ARCHIVES" fetch origin main
git -C "$ARCHIVES" checkout -b "$BRANCH" origin/main
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

完了したら PR の URL を返す。
