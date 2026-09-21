---
name: find-note
description: >-
  brain vault の知識ノートを検索し、過去の自分の記録から答えを引く。
  「前にもやった気がする」「どこかに書いた気がする」
  「brain にあるかも」と言ったとき、またはエラー調査・ツールの設定・環境構築の相談で
  ユーザーが過去に同じ問題を踏んでいそうなときに使用する。
argument-hint: 検索キーワード (任意)
model: sonnet
---

# /find-note

brain vault の知識ノートを検索し、過去の記録から答えを引く。doc skill が書く側、find-note skill が読む側。

## vault の場所

git remote が `nozomiishii/brain` を指す clone を、現在の task、ホストの project 一覧、既存の local clone の順で探し、その `brain/` 配下を使う。clone が無ければ、検索できないことを伝えて終わる。

## 検索のやり方

ノートは日本語タイトルがそのままファイル名。frontmatter に tags と aliases があり、本文は `[[wiki-link]]` で相互リンクされる。

- 内容の grep を主にする。ファイル名の一致だけでは拾えない。Terraform で探すと OpenTofu ノートの本文にだけ書いてある、のような表記ゆれがある
- 検索語は日本語と英語、ツールの別名、エラーメッセージの断片を試す
- ヒットしたノートは本文を読み、要点と Obsidian で開くリンクを報告する

リンクは `https://obsid.net/?vault=<vault 名>&file=<ノートのパス>` の形。ノートのパスは vault ルートからの相対パスで、末尾の `.md` を外す。`vault` と `file` の値は別々に URL エンコードする。リンクテキストはエンコードせず `<ノートのパス>（Obsidian で開く）` にする。

## 調べる順番

エラーや設定の調査では、公式ドキュメントや web より先に vault を 1 回 grep する。この環境でどう直したか・どう運用しているかはノートにしかない。

ヒットしなければ、ノートに無かったことを伝え、ユーザーの質問をそのまま公式ドキュメント・web の検索に回す。
