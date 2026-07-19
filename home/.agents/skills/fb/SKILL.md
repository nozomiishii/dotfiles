---
name: fb
description: >-
  セッションの振り返りを一括実行する。
  doc と retro の候補を同時に提示し、ユーザーが一覧から対応を選ぶ。
  Claude Code で /fb、Codex で $fb と入力したときに使用する。
---

# /fb

doc（記録の保存）と retro（業務改善）の候補を同時に洗い出し、1 つの一覧で提示する。

## 候補の洗い出し

会話全体を振り返り、doc 候補と retro 候補を同時に抽出する。判定基準は各スキルに従う:

- doc 候補: sibling の [doc SKILL.md](../doc/SKILL.md) を明示的に読み、その判定フローで置き場を決定
- retro 候補: sibling の [retro SKILL.md](../retro/SKILL.md) を明示的に読み、その検出基準で引っかかりを検出

## 一覧の提示

候補を 1 つの表にまとめて提示する。

| # | 種別 | 内容 | 置き場 / 対応 |
| --- | ---- | ---- | ------------- |

- 種別: doc / retro
- 置き場 / 対応: doc は置き場（issue, ADR, docs/, AGENTS.md, note）、retro は推奨する対応方法

ユーザーが番号で取捨選択し、対応方法を指定する。

## 対応の実行

- doc 項目: doc skill の実行手順に従う
- retro 項目: retro skill の対応フローに従う

## スキップ条件

- doc: 残す候補がなければスキップ
- retro: 改善候補がなければスキップ
- 両方スキップなら「特に振り返り事項なし」で終了
