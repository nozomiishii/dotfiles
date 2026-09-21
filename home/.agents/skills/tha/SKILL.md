---
name: tha
description: 会話やプランで行った変更を PR にして、pr skill に引き継いで mergeable まで持っていく。
disable-model-invocation: true
model: sonnet
---

# /tha

会話やプランで行った変更を PR にし、pr skill に引き継いで mergeable まで持っていく。マージはしない。

関連する変更だけを commit する。無関係な変更を巻き込まない。

## branch と PR

今の branch または commit に紐づく PR の状態で決める。

- open PR がある: 再利用し、追加 commit として push する。新しい PR は作らない。候補が複数あれば、どれを使うかユーザーに確認する
- PR が一度も作られていない作業 branch にいる: その branch のまま PR を作る
- detached HEAD で紐づく PR が無い: 今の commit から新しい branch を作って PR を作る
- base branch にいる、または今の branch の PR が MERGED / CLOSED: 最新の base branch から新しい branch を作って PR を作る。base branch へは切り替えない

新しい branch 名は、環境変数 `CODEX_THREAD_ID` がある Codex App では `codex/<変更内容>-<task ID 由来の suffix>` にする。他のホストでは repo の命名規約に従う。detached HEAD というだけで Codex と決めつけない。

## 外部 repo と fork

base と head のどちらかが自分の管理外の repo なら、stage・commit・push・PR 作成より先に sibling の [oss SKILL.md](../oss/SKILL.md) を明示的に読み、その承認境界に従う。所有者を判定できないときも同じ。

fork の PR を再利用するときは head repo へ push する。base repo に同名の branch を作らない。head repo や書き込み権限を確かめられないときは、推測せず止まる。

## 引き継ぎ

PR 作成または push の後、sibling の [pr SKILL.md](../pr/SKILL.md) を明示的に読んで引き継ぐ。PR 番号または URL を渡す。pr skill は explicit-only なので、暗黙には選ばれない。

draft PR は引き継がない。修正途中の前提なので、CI の失敗を勝手に直さない。
