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

/wt スキルで作る。REPO は `$HOME/Code/nozomiishii/brain`、branch 名は `note-<トピックの英訳 kebab-case>`。

## ノート作成

選ばれたトピックごとに `brain/main/<ノート名>.md` に作成する。ノート名はトピック名そのままの日本語。スペースを含んでよく、ファイル名に使えない文字だけ置き換える。

frontmatter のスキーマは `$REPO/scripts/schemas/obsidian/main.ts` を読んで従う。

ノートの要件:

- タグは既存ノートで使われているタグから選ぶ（git, typescript, shell 等）。合うものが無ければ新設する
- session URL や出自情報は含めない
- 見出しはトピックに応じて自然に。会話中のユーザーの疑問が核になるセクションは、その質問を簡潔にした疑問形にする（例: 「何を解決するのか？」「どう使い分ける？」）
- 関連する概念は `[[wiki-link]]` でつなぐ。ノートを書く前に既存ノートの一覧を取得し、実在するノートだけを wiki-link にする。存在しないノートへの wiki-link は作らない
  ```shell
  WT="$REPO/.claude/worktrees/$SLUG"
  ls "$WT/brain/main/" | sed 's/\.md$//'
  ```
- コード例・図は必要に応じて含める
- そのままブログに公開しても問題ない品質
- 既存の brain vault のノートとつながりを意識する

## 重複チェックと関連ノート整理

ノートを作成したら、コミットする前に既存ノートとの重複・関連を確認する。

```shell
# タイトル・タグ・キーワードで既存ノートを検索
WT="$REPO/.claude/worktrees/$SLUG"
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

確認用にノートのファイルパスを出力する。スペース入りパスでもリンクが壊れないよう、`$REPO` を展開したフルパスをそのまま出す:

```
$REPO/.claude/worktrees/<SLUG>/brain/main/<ノート名>.md
```

承認を得てから次へ進む。

## commit, push, PR

worktree 内で commit → push し、PR を作成する。複数ノートは 1 つの PR にまとめる。

```sh
WT="$REPO/.claude/worktrees/$SLUG"
# 作成したファイルだけを個別に add する。
# `git add "brain/main/"` はディレクトリ全体をステージするため、
# 他の worktree や並行セッションが残したファイルまで巻き込む。
git -C "$WT" add "brain/main/<ノート名1>.md" "brain/main/<ノート名2>.md"
git -C "$WT" commit -m "chore: add <topic> note"
git -C "$WT" push -u origin "$SLUG"
BODY_FILE=$(mktemp) && cat > "$BODY_FILE" <<'EOF'
（日本語の PR 本文）
EOF
gh pr create -R nozomiishii/brain --base main --head "$SLUG" --title "chore: add <topic> note" --body-file "$BODY_FILE"
```

- `--head` を必ず付ける（cwd が brain worktree ではない場合があるため）
- `git add` はファイル単位で指定する。ディレクトリ指定やワイルドカードは禁止
- PR 本文: 日本語
- merge はユーザーが手動で行う。AI はマージしない
