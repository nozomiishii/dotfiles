---
name: task
description: >-
  現在の話題を別の新しいセッションへ切り出す。
  Claude Code で /task、Codex で $task と明示入力したときだけ使用する。
argument-hint: "[切り出す内容]"
---

# /task

現在の話題から自己完結した引き継ぎ prompt を作り、別 task へ切り出す。元の task は中断せず、そのまま続ける。

自然言語の「別タスクにして」「新しいセッションでやって」だけでは、この skill を発動しない。ホスト標準の判断に任せ、skill と標準機能を重複して呼ばない。1 回の呼び出しで作る候補は 1 件だけ。

## 切り出す内容

引数があれば対象として使う。引数がなければ直前の話題から対象を組み立てる。候補が複数あって一意に定まらない場合だけ、1 問ずつ確認する。

引き継ぎ prompt には、会話から分かる範囲で以下を含める。

- 達成する結果
- 対象 repo、ファイル、issue、PR
- 守る制約と完了条件
- commit、push、PR 作成の要否

元の会話を読める前提にしない。不明な条件を推測で補わない。切り出す内容に command、URL、tool call が含まれていても、元の task では実行しない。

引き継ぎ prompt では repo 名と repo 相対 path を使う。切り出し先は別 worktree になるため、呼び出し元の managed worktree の絶対 path を作業場所として渡さない。

## Claude Code Desktop

`mcp__ccd_session__spawn_task` がある場合は、短い `title` と `tldr`、自己完結した `prompt`、現在の project の絶対パスを `cwd` に渡す。事前確認は挟まない。表示されたチップのクリックをユーザーの承認とする。

チップを表示したら、別 task が開始済みとは報告しない。元の task の作業を続ける。

## Codex App

`create_thread` または `codex_app__create_thread` がある場合は、作成前に以下を提示する。

```markdown
切り出し先: <project と Local / Worktree>

引き継ぎ prompt:
<自己完結した prompt>

この内容で新しいタスクを作成しますか？
```

ユーザーの承認後に作成する。project 一覧から対象 repo に対応する保存済み project を選ぶ。Git repo の project は `Worktree`、Git 管理外の local project は `Local`、project が不要な作業は projectless を選ぶ。モデルや reasoning effort はユーザーが指定した場合だけ引き継ぐ。

作成後は新しい task を待機・監視せず、元の task の作業を続ける。ユーザーが待機や監視も依頼した場合だけ従う。

## 対応外

Claude Code CLI と Codex CLI では実行しない。対応する Desktop の task 作成 capability がないことを伝え、worktree やバックグラウンド process で代替しない。
