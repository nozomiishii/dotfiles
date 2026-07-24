# 記録の置き場判定は doc スキルを正本にする

Status: accepted
Date: 2026-07-24

## Context — 判断を迫られた状況

ドキュメントの置き場が issue / repo の docs / brain vault に分かれ、書く場所に迷う・docs が腐る・探すとき見つからないの 3 つが起きていた。かつては設計や決定も issue に書く issue ドリブンの運用だった。議論の経緯は [nozomiishii/brain#268](https://github.com/nozomiishii/brain/issues/268)。

## Decision — 決めたこと

- 置き場の判定フローの正本を /doc スキルに置く。グローバル設定には正本への参照だけを書き、二重管理しない
- 役割を固定する: issue は動的な情報(思いつき・保留・未着手の議論・時系列の記録)、決着した判断は対象 repo の `docs/decisions/` に ADR、今の事実(仕様・手順)は `docs/`、repo に限らない学びは brain
- 決定やプランを issue に書き続ける旧フローは踏襲しない。スキルの設計判断も ADR に書き、SKILL.md からは「設計の判断は ADR、経緯は issue」の形で参照する

## Consequences — 決定がもたらすもの

- 「なんでこうしたんだっけ」の答えが repo の `docs/decisions/` に集まり、issue は検索の入口と時系列ログに徹する
- 既存スキルの「設計の経緯は issue」参照は前例として残さず、ADR 参照へ移行する
