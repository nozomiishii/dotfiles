# ADR のファイル名は連番でなく日本語タイトルにする

Status: accepted
Date: 2026-07-05

## Context — 判断を迫られた状況

ADR の慣例は 0001- 形式の連番だが、並列 worktree で複数セッションが同時に ADR を作ると次番号を取り合って衝突する。読み手は自分と AI エージェントのみで、短い番号で口頭引用するチーム用途がない。brain vault には日本語ファイル名の文化があり、タイトルを英訳 slug に変換する作業は毎回の摩擦になる。

## Decision — 決めたこと

全 repo の ADR で、ファイル名はタイトル (日本語の決定文) をそのまま使う。連番・日付は付けず、日付と状態は本文の Date / Status 行に書く。

## Consequences — 決定がもたらすもの

並列セッションでの衝突がなくなり、タイトル = ファイル名で変換ゼロ・grep 一発になる。ls での時系列一覧は失われる (必要になれば git log か自動生成 index で補う)。adr-tools など連番前提の既存ツールは使えない。ファイル名に使えない文字がタイトルに含まれるときだけ置き換えが要る。

決着元: [nozomiishii/brain#268](https://github.com/nozomiishii/brain/issues/268)
