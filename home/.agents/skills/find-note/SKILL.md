---
name: find-note
description: >-
  brain vault のノートを検索し、過去の調査結果・好み・知識を引く。
argument-hint: 検索キーワード (任意)
model: sonnet
---

# /find-note

brain vault のノートを検索し、過去の調査結果・好み・知識を引く。doc skill が書く側、find-note skill が読む側。

## vault の場所

git remote が `nozomiishii/brain` を指す clone を、現在の task、ホストの project 一覧、既存の local clone の順で探し、その `brain/` 配下を使う。clone が無ければ、検索できないことを伝えて終わる。

## 検索のやり方

ノートは日本語タイトルがそのままファイル名。frontmatter に tags と aliases があり、本文は `[[wiki-link]]` で相互リンクされる。

- 内容の grep を主にする。ファイル名の一致だけでは拾えない。Terraform で探すと OpenTofu ノートの本文にだけ書いてある、のような表記ゆれがある
- 検索語は日本語と英語、ツールの別名、エラーメッセージの断片を試す
- ヒットしたノートは本文を読み、要点と Obsidian で開くリンクを報告する
- 判定が曖昧な結果は確定させず、未確定として分けて伝える
- ノートの最終更新日（git の最終コミット日など）を確認し、情報が古くなっている可能性があればその旨を添える
- 該当するノートが見つからなければ、ノートに無かったことを伝える

リンクは `https://obsid.net/?vault=<vault 名>&file=<ノートのパス>` の形。ノートのパスは vault ルートからの相対パスで、末尾の `.md` を外す。`vault` と `file` の値は別々に URL エンコードする。リンクテキストはエンコードせず `<ノートのパス>（Obsidian で開く）` にする。
