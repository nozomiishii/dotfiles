---
name: archive
description: >-
  自分が管理するリポジトリで使わなくなったファイルを nozomiishii/archives リポジトリへ退避するときに使用する。
  「アーカイブして」「archives に退避して」と言ったときに使用する。
---

# /archive

自分が管理するリポジトリで不要になったファイルを `nozomiishii/archives` に退避する PR と、元のリポジトリから削除する PR を作る。

## 対象を確定する

会話または引数から、対象ファイルと元のリポジトリを分けて確定する。

- 対象は元のリポジトリからの相対パスに限定する。空のパス、`..`、制御文字を含むパスは扱わない
- リポジトリの識別には remote の owner と name を使う。現在の作業場所やディレクトリ名だけで推測しない
- 候補が複数ある、または特定できない場合はユーザーに確認する
- clean な tracked file は、検証した index または HEAD の内容を使う
- dirty な tracked file は staged、unstaged、削除を区別して差分を示す。index、HEAD、worktree のどの版を退避するかユーザーに確認し、選択前にコピーしない。worktree 版は untracked file と同じ境界を検証する
- 削除済みの tracked file は、検証した参照先の内容を使う
- untracked file は、リポジトリ内にあり symlink を経由しない通常ファイルだけを扱う
- symlink、submodule、device などの特殊な対象は処理を止め、扱いをユーザーに確認する。リンク先をたどってリポジトリ外を読まない

全ファイルを secret、credential、個人情報について検査する。疑わしい内容があれば、別のリポジトリへコピーする前に停止してユーザーに確認する。

## archives リポジトリを準備する

`nozomiishii/archives` は元のリポジトリと別の作業単位に切り出す。配置場所を固定せず、remote identity が一致する作業場所を使う。見つからない場合は利用可能なリポジトリ準備機能を使い、それも無ければ配置先をユーザーに確認する。

作業開始前に次を満たすことを確認する。

- 作業場所の remote identity が `nozomiishii/archives` と一致する
- 最新の main を比較元として取得している
- main へ切り替えず、作成済みの作業ブランチを使う

## 配置する

`<repo-dir>/<元のディレクトリ構造>` に、元のパスとファイル名を保って配置する。`nozomiishii` 配下のリポジトリは repo 名を `<repo-dir>` にし、それ以外は `<owner>/<repo>` にする。

```text
archives/
  dotfiles/
    scripts/darwin/claude_insights.sh
  other-owner/other-repo/
    src/legacy.ts
```

同名ファイルが存在する場合は上書きせず、ユーザーに確認する。書き込み前に、既存の親要素が symlink でなく、実体が archives リポジトリ内に収まることを確認する。配置先が symlink または特殊な対象なら停止する。

複数ファイルは 1 つの PR にまとめる。コミットと PR のタイトルは `chore: archive <何を> from <repo>` とし、PR 本文に次を含める。

- 元のリポジトリとパス
- 削除理由
- 関連する PR または Issue

## 元のリポジトリから削除する

archives 側の PR を作成した後、元のリポジトリ専用の作業場所で対象ファイルを削除する PR を作る。別のリポジトリ用の作業場所から変更しない。PR 本文には archives 側の PR を含める。

両方の PR の URL をまとめて報告する。PR はマージしない。
