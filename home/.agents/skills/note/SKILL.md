---
name: note
description: >-
  会話で学んだことをトピック単位で brain vault に知識ノートとして保存する。
  ユーザーが /note と入力したとき、または「ノートに残して」「ノートにして」「メモしておいて」と言ったときに使用する。
argument-hint: トピック名（任意）
---

# /note

会話で得た知識を brain vault に Zettelkasten 形式のノートとして保存する。

## トピック抽出

会話を振り返り、学んだトピックの候補を一覧提示する。

- トピック名 + サマリーの形式
- `$ARGUMENTS` が指定されていれば、そのトピックを優先する
- 候補がなければ「特になし」で終了

ユーザーが保存したいトピックを選んでから次へ進む。

## brain vault の worktree 作成

/wt スキルで作る。REPO は `$HOME/Code/nozomiishii/brain`、SLUG は `note-<kebab-case-slug>`。

## ノート作成

選ばれたトピックごとに `brain/main/<slug>.md` に作成する。slug はトピック名から英小文字 kebab-case。

frontmatter のスキーマは `scripts/schemas/main.ts` を読んで従う。

ノートの要件:

- タグは内容に応じて適切なものを付ける（git, typescript, shell 等）
- session URL や出自情報は含めない
- 見出しはトピックに応じて自然に。会話中のユーザーの疑問が核になるセクションは、その質問を簡潔にした疑問形にする（例: 「target って何？」「polyfill と構文変換は何が違う？」）
- 関連する概念は `[[wiki-link]]` でつなぐ
- コード例・図は必要に応じて含める
- そのままブログに公開しても問題ない品質
- 既存の brain vault のノートとつながりを意識する

## 重複チェックと関連ノート整理

ノートを作成したら、コミットする前に既存ノートとの重複・関連を確認する。

```shell
# タイトル・タグ・キーワードで既存ノートを検索
WT="$BRAIN/.claude/worktrees/$SLUG"
grep -rl "<キーワード>" "$WT/brain/main/" | head -10
```

確認する観点:

- 同じトピックのノートが既に存在しないか（重複防止）
- 関連する既存ノートがあれば `[[wiki-link]]` で相互リンクを張る
- 既存ノートに追記した方が良い内容であれば、新規作成ではなく追記を提案する

結果をユーザーに報告する:

- 重複候補が見つかった場合: 「既存の `<ノート名>` と内容が重なりそうです。追記 / 新規 / スキップのどれにしますか？」
- 関連ノートが見つかった場合: 「`<ノート名>` に wiki-link を追加しました」
- 見つからなかった場合: そのまま次へ進む

## ユーザー確認

ノートを作成したら、コミットする前にユーザーに内容を確認してもらう。

確認用にノートのファイルパスを出力する。スペース入りパスでもリンクが壊れないよう、`~` 展開したフルパスをそのまま出す:

```
~/Code/nozomiishii/brain/.claude/worktrees/<SLUG>/brain/main/<ノート名>.md
```

承認を得てから次へ進む。

## commit, push, PR

worktree 内で commit → push し、PR を作成する。複数ノートは 1 つの PR にまとめる。

```sh
WT="$BRAIN/.claude/worktrees/$SLUG"
# 作成したファイルだけを個別に add する。
# `git add "brain/main/"` はディレクトリ全体をステージするため、
# 他の worktree や並行セッションが残したファイルまで巻き込む。
git -C "$WT" add "brain/main/<slug-1>.md" "brain/main/<slug-2>.md"
git -C "$WT" commit -m "chore: add <topic> note"
git -C "$WT" push -u origin "$SLUG"
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の PR 本文）
EOF
gh pr create -R <brain owner/repo> --base main --head "$SLUG" --title "chore: add <topic> note" --body-file "$BODY_FILE"
```

- `--head` を必ず付ける（cwd が brain worktree ではない場合があるため）
- `git add` はファイル単位で指定する。ディレクトリ指定やワイルドカードは禁止
- PR 本文: 日本語
- merge はユーザーが手動で行う。AI はマージしない
