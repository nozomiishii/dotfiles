---
name: archive
description: >-
  自分が管理するリポジトリで使わなくなったファイルを nozomiishii/archives リポジトリへ退避するときに使用する。
  「アーカイブして」「archives に退避して」と言ったときに使用する。
---

# /archive

自分が管理する repo で不要になったファイルを `nozomiishii/archives` へ退避する PR と、元の repo から削除する PR を作る。どちらもマージせず、両方の PR の URL をまとめて報告する。

## 対象

会話または引数から、対象ファイルと元の repo を確定する。repo は remote の owner と name で識別し、ディレクトリ名から推測しない。特定できなければユーザーに確認する。

- 未 commit の変更があるファイルは、どの版を退避するかユーザーに確認してからコピーする
- 対象は repo 内の通常ファイルに限る。symlink、submodule、特殊ファイルは止まって確認し、リンク先をたどって repo の外を読まない
- secret、credential、個人情報が疑われる内容があれば、コピー前に止まって確認する

## 配置

`<repo-dir>/<元のディレクトリ構造>` に、元のパスとファイル名を保って置く。`<repo-dir>` は `nozomiishii` 配下なら repo 名、それ以外は `<owner>/<repo>` にする。同名ファイルがあれば上書きせず確認する。配置先やその親が symlink なら止まる。

```text
archives/
  dotfiles/
    scripts/darwin/claude_insights.sh
  other-owner/other-repo/
    src/legacy.ts
```

## PR

複数ファイルは 1 つの PR にまとめる。commit と PR のタイトルは `chore: archive <何を> from <repo>`。PR 本文には元の repo とパス、削除理由、関連する PR または Issue を書く。

archives 側の PR を先に作り、削除側の PR 本文に archives 側の PR を載せる。2 つの repo は別々の作業場所で変更する。
