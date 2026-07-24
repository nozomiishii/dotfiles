# スキルはドキュメントの TDD で作る

Status: accepted
Date: 2026-07-24

## Context — 判断を迫られた状況

superpowers plugin を削除した際、14 スキル中 13 個は built-in 機能・自作スキル・AGENTS.md ルールでカバーできたが、writing-skills の方法論だけは CLAUDE.md では表現しきれなかった。superpowers 版は英語・太字・手順番号で書かれており、文書規約ともそのままでは合わない。議論の経緯は [#1292](https://github.com/nozomiishii/dotfiles/issues/1292)。

## Decision — 決めたこと

- スキル(SKILL.md)の新規作成・編集はドキュメントの TDD で行う。スキルなしで subagent が失敗するのを見てから書き(RED)、失敗に対する最小限を書き(GREEN)、読ませて直るのを確認してから確定する(REFACTOR)
- superpowers からは方法論だけを抽出し、AGENTS.md の文書規約(日本語・太字なし・手順番号なし)に沿った自作スキル /skill として再構築する

## Consequences — 決定がもたらすもの

- 1 行の編集でもテストを経ずにスキルを確定できない。書くコストは上がるが、読まれないスキル・効かないスキルを作るコストが消える
- 手順の正本は skill スキルが持つ
