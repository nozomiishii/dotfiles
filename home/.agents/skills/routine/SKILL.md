---
name: routine
description: >-
  Claude Code Routine を追加・変更・削除したいとき、または .routines/ と cloud trigger を同期するときに使用する。
argument-hint: <routine-name> <概要>
---

# /routine

Claude Code Routine を git 管理で追加・変更し、`.routines/` の frontmatter と cloud trigger を一致させる。Codex から実行する場合も、Codex の scheduled task や automation で代替しない。Claude Code Routine を読み書きできなければ停止する。片側だけ更新しない。

## 正本

- prompt の正本は `nozomiishii/brain` の `.routines/<name>.md`
- cloud trigger の Instructions は `.routines/<name>.md を Read し、その指示に従って実行お願い。` だけにする
- 全 routine に `nozomiishii/brain` と対象リポジトリを関連付ける

## 2 回の実行に分ける

`.routines/` の変更を先に PR で main へ反映し、反映後の別の実行で trigger を作成・更新する。同じ実行で続けない。main に無い内容、またはユーザーと合意した内容と main が食い違う内容に対して、trigger を触らない。

既存 routine を変更する前に、下の整合性の表にある項目と正確な次回実行時刻を取得する。取得できなければ frontmatter も trigger も変更しない。

## 削除

trigger の削除は [Routine 管理画面](https://claude.ai/code/routines)でユーザーに行ってもらう。削除予定の routine を先に無効化しない。管理画面から見えなくなり削除できなくなる。trigger が消えた後、`.routines/<name>.md` を削除する PR を作る。

## 新規 routine を設計する

依頼から読み取れない項目だけユーザーに確認し、内容を合意してからファイルを作る。既存の `.routines/` を読み、frontmatter と prompt の形式を合わせる。

- 達成したいこと、成果物、成功と失敗の基準
- 対象リポジトリ、外部リソース、connector の要否
- 頻度、曜日、時刻、利用する model
- 既存 routine との責務の重複、エラー時に続行するか停止するか

name は `^[a-z0-9]+(?:-[a-z0-9]+)*$` に一致する `<頻度>-<対象>`。頻度は `daily`、`weekly`、`biweekly`、`monthly`、`quarterly`、`biannual` から選ぶ。

時刻の指定がなければ 05:00 JST とする。この既定値は質問せず、完了報告に記載する。

monthly は次を満たす。

- 発火日は、JST 2〜28 日のうち既存の monthly routine と重ならない最小の日
- name とファイル名は `monthly-<2桁の日>-<対象>`
- 発火時刻は 05:00 JST

型は `.routines/_templates/` にある次から選ぶ。placeholder を残さない。必須 section を削る場合は理由をユーザーと合意する。

| 型       | 用途                     | prompt に含める条件                                                |
| -------- | ------------------------ | ------------------------------------------------------------------ |
| news     | 定期的な情報収集         | 収集期間、TL;DR、前回 Issue                                        |
| watch    | 条件成立までの監視       | ベースライン、判定基準、検出時の印、達成後に停止を提案する終了条件 |
| audit    | 自分のリソースの定点監査 | 対象選定、過去の判断との照合、却下または保留した内容の再提案禁止   |
| reminder | 手作業の催促             | 手順、完了ログ                                                     |

frontmatter は次のとおりにする。

- `repos` に対象リポジトリと `nozomiishii/brain` を含める
- `connectors` は必要なものだけにする。不要なら空にする
- cron は UTC で記述し、JST の実行時刻をコメントで添える
- `type` は使った template 名と一致させる

## PR

brain リポジトリで PR を作る。新規追加のタイトルは `feat: add <name> routine prompt`、本文は日本語にする。マージしない。PR URL と、main への反映後に同期を再実行する必要があることを報告する。

## cloud trigger

frontmatter と一致する trigger を作成・更新したら、frontmatter に無い connector をすべて外す。正確な次回実行時刻を JST に変換し、frontmatter の schedule コメントと並べて示す。意図した曜日と時刻に一致しない場合は schedule を直す。

同期では main の全 routine と全 trigger を name で照合し、差がある項目だけ更新する。照合できない routine は更新せず報告する。`type` はローカルだけの情報として同期しない。

name を変更した routine は、変更履歴から旧 name を特定して既存 trigger と照合する。特定できなければ trigger を触らず報告する。既存 trigger を更新して実行履歴を保ち、新しい trigger への置き換えで履歴を切らない。model を変更するときは、対象リポジトリや環境など変更対象でない構成をすべて保持する。

## 整合性を確認する

終了前に `.routines/` の全 frontmatter と全 trigger を照合する。

| 項目       | 一致条件                                                    |
| ---------- | ----------------------------------------------------------- |
| name       | trigger 名と frontmatter の name                            |
| schedule   | trigger の schedule と frontmatter の cron                  |
| model      | 表記の違いを考慮した trigger と frontmatter の model        |
| repos      | trigger と frontmatter の repos                             |
| connectors | trigger と frontmatter の connectors                        |
| prompt     | Instructions が正しい `.routines/<name>.md` を参照する stub |

未設定の値も差分として扱う。routine ごとの結果を表で示し、差分があれば修正するかユーザーに確認する。差分がなくても表を示す。
