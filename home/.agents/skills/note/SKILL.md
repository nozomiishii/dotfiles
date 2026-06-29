---
name: note
description: >-
  会話で学んだことをトピック単位で brain vault に知識ノートとして保存する。
  ユーザーが /note と入力したときに使用する。
argument-hint: トピック名（任意）
---

# /note

会話で得た知識を brain vault に Zettelkasten 形式のノートとして保存する。

## トピック抽出

会話を振り返り、学んだトピックの候補を一覧提示する。

- トピック名 + 1 行サマリーの形式
- `$ARGUMENTS` が指定されていれば、そのトピックを優先する
- 候補がなければ「特になし」で終了

ユーザーが保存したいトピックを選んでから次へ進む。

## brain vault の worktree 作成

```shell
BRAIN="$HOME/Code/nozomiishii/brain"
SLUG="note-<kebab-case-slug>"
git -C "$BRAIN" fetch origin main --quiet
git -C "$BRAIN" worktree add "$BRAIN/.claude/worktrees/$SLUG" -b "$SLUG" origin/main
```

## ノート作成

選ばれたトピックごとに `brain/main/<slug>.md` に作成する。slug はトピック名から英小文字 kebab-case。

ノートのスキーマ:

```markdown
---
tags:
  - <内容に合ったタグ>
created: <today YYYY-MM-DD>
---

# <トピック名>

（1 つの概念・知識を自己完結的に説明する本文）
```

ノートの要件:

- タグは内容に応じて適切なものを付ける（git, typescript, shell 等）
- session URL や出自情報は含めない
- 見出し構造はトピックに応じて自然に
- 関連する概念は `[[wiki-link]]` でつなぐ
- コード例・図は必要に応じて含める
- そのままブログに公開しても問題ない品質
- 既存の brain vault のノートとつながりを意識する

## commit, push, PR

worktree 内で commit → push し、PR を作成する。複数ノートは 1 つの PR にまとめる。

```sh
WT="$BRAIN/.claude/worktrees/$SLUG"
git -C "$WT" add "brain/main/"
git -C "$WT" commit -m "docs: add <topic> note"
git -C "$WT" push -u origin "$SLUG"
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の PR 本文）
EOF
gh pr create -R <brain owner/repo> --base main --head "$SLUG" --title "docs: add <topic> note" --body-file "$BODY_FILE"
```

- `--head` を必ず付ける（cwd が brain worktree ではない場合があるため）
- PR タイトル: Conventional Commits、英語
- PR 本文: 日本語
- merge はユーザーが手動で行う。AI はマージしない
