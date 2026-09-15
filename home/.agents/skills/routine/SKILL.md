---
name: routine
description: >-
  Claude Code Routine を追加・変更するとき、または .routines/ と cloud trigger を同期するときに使用する。
argument-hint: <routine-name> <概要>
---

# /routine

Claude Code Routine を git 管理で追加・変更する。Codex から実行する場合も、管理対象を Codex の scheduled task や automation に置き換えない。

## 正本と同期の境界

- prompt の正本は `nozomiishii/brain` の `.routines/<name>.md`
- cloud trigger の Instructions は `.routines/<name>.md を Read し、その指示に従って実行お願い。` だけにする
- 全 routine に `nozomiishii/brain` と対象リポジトリを関連付ける
- `.routines/` の frontmatter を先に main へ反映し、反映後の別の実行で cloud trigger を同期する
- frontmatter の変更と trigger の変更を同じ実行で続けて行わない
- Codex から Claude Code Routine を読み書きできない場合は停止する。片側だけ更新せず、Codex の automation で代替しない

既存 routine を変更する前に、name、Instructions、repos、schedule、model、connectors、正確な次回実行時刻を取得する。新規作成では、登録後に同じ項目を取得して検証できることをファイル変更前に確認する。いずれかを満たせない場合は、frontmatter と trigger の両方を変更しない。

削除は [Routine 管理画面](https://claude.ai/code/routines)でユーザーに行ってもらう。

## 新規 routine を設計する

brain リポジトリは配置場所で決めず、remote identity で特定する。見つからない場合は利用可能なリポジトリ準備機能を使う。既存の `.routines/` と同じ型のファイルを 1〜2 件読み、frontmatter と prompt の形式を確認する。

依頼から読み取れない項目だけをユーザーに確認する。

- 達成したいこと
- 手作業の自動化か、新しい情報の収集か
- 成果物
- 成功と失敗の基準
- 対象リポジトリと外部リソース
- 頻度、曜日、時刻
- 利用する model
- 既存 routine との責務の重複
- connector の要否
- エラー時に続行するか停止するか

時刻の指定がなければ 05:00 JST とする。この既定値は質問せず、完了報告に記載する。

routine name は `^[a-z0-9]+(?:-[a-z0-9]+)*$` に一致する `<頻度>-<対象>` とする。頻度は `daily`、`weekly`、`biweekly`、`monthly`、`quarterly`、`biannual` から選ぶ。

monthly は次を満たす日を選ぶ。

- JST 2〜28 日のうち、既存の monthly routine と重ならない最小の日
- name とファイル名は `monthly-<2桁の日>-<対象>`
- 発火時刻は 05:00 JST

routine は `.routines/_templates/` にある次の型から選ぶ。

| 型       | 用途                     | prompt に含める条件                                                |
| -------- | ------------------------ | ------------------------------------------------------------------ |
| news     | 定期的な情報収集         | 収集期間、TL;DR、前回 Issue                                        |
| watch    | 条件成立までの監視       | ベースライン、判定基準、検出時の印、達成後に停止を提案する終了条件 |
| audit    | 自分のリソースの定点監査 | 対象選定、過去の判断との照合、却下または保留した内容の再提案禁止   |
| reminder | 手作業の催促             | 手順、完了ログ                                                     |

prompt には前提、タスク、出力形式、制約を含める。ユーザーと内容が合意できてからファイルを作る。

## `.routines/<name>.md` を作る

選んだ型の template を使い、placeholder を残さない。

- `repos` に対象リポジトリと `nozomiishii/brain` を含める
- `connectors` は必要なものだけにする。不要なら空にする
- cron は UTC で記述し、JST の実行時刻をコメントで添える
- frontmatter の `type` は使った template 名と一致させる
- template の必須 section を削る場合は理由をユーザーと合意する

brain リポジトリ専用の作業場所で変更し、commit、push、PR 作成まで行う。PR のタイトルは `feat: add <name> routine prompt`、本文は日本語にする。PR はマージしない。

PR URL と、main への反映後に同期を再実行する必要があることを報告して終了する。未反映の内容に対して trigger を作成または更新しない。

## trigger 操作前に検証する

新規作成、変更、同期のいずれでも、trigger を変更する前に次を確認する。

- 比較対象が最新の main である
- `.routines/<name>.md` が main に反映済みである
- main の内容が今回ユーザーと合意した内容と完全に一致する
- ローカルブランチまたは open PR にだけ変更がある場合は停止する

## cloud trigger を作成する

検証を通過した別の実行で、frontmatter と一致する trigger を作る。

- name
- Instructions の stub
- 対象リポジトリと `nozomiishii/brain`
- schedule
- model
- connectors

作成直後に connector を確認し、frontmatter に無い connector をすべて外す。

作成結果に含まれる正確な次回実行時刻を JST に変換し、frontmatter の schedule コメントと並べて示す。意図した曜日と時刻に一致しない場合は schedule を直す。

## 変更を同期する

frontmatter を変更した場合は、変更 PR を作って終了する。main への反映後、別の実行で trigger を同期する。

main にある全 routine と全 trigger を name で照合し、差がある項目だけを更新する。照合できない routine は更新せず報告する。name を変更した場合は変更履歴から旧 name を特定する。旧 name を特定できない場合も、その routine を更新しない。

- `model` は trigger の model と一致させる
- `schedule` は trigger の schedule と一致させる
- `connectors` は trigger の connector と一致させ、余分な connector を外す
- `type` はローカルだけの情報として同期しない

model を変更するときは、既存 trigger の実行内容、対象リポジトリ、環境など、変更対象でない構成をすべて保持する。現在の構成を完全に取得できない routine は更新せず報告する。

name を変更するときは既存 trigger を更新し、実行履歴を保つ。trigger の name と Instructions が参照するファイル名を両方変更する。新しい trigger への置き換えで履歴を切らない。

schedule を変更した場合は、更新結果の正確な次回実行時刻を JST に変換し、frontmatter の schedule コメントと並べて示す。

## 整合性を確認する

すべての経路で、終了前に `.routines/` の全 frontmatter と全 trigger を照合する。

| 項目       | 一致条件                                                    |
| ---------- | ----------------------------------------------------------- |
| name       | trigger 名と frontmatter の name                            |
| schedule   | trigger の schedule と frontmatter の cron                  |
| model      | 表記の違いを考慮した trigger と frontmatter の model        |
| repos      | trigger と frontmatter の repos                             |
| connectors | trigger と frontmatter の connectors                        |
| prompt     | Instructions が正しい `.routines/<name>.md` を参照する stub |

未設定の値も差分として扱う。routine ごとの結果を表で示し、差分があれば修正するかユーザーに確認する。差分がなくても表を示す。

削除予定の routine を先に無効化しない。管理画面から見えなくなり削除できなくなる。
