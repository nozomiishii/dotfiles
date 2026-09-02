---
status: accepted
date: 2026-09-02
---

# dev のプランは plan mode に入らず進める

## 背景と課題

dev スキルは Claude Code でプランを固めるときに plan mode に入っていた。auto mode で始めたセッションでも、plan mode の間は sandbox のネットワーク許可が[自動で広がらず](https://code.claude.com/docs/en/sandboxing#sandbox-modes)、一次情報の確認や敵対的レビューのたびに許可プロンプトで手が止まっていた。plan mode を抜けるときも[承認時に選んだ選択肢で次の mode が決まり](https://code.claude.com/docs/en/permission-modes#review-and-approve-a-plan)、auto mode に戻る保証がなかった。

## 検討した選択肢

- plan mode に入り、承認時に auto mode を選ぶ: 承認前の編集をホストが機械的に止める。プラン中の許可プロンプトは消えない
- plan mode に入らず、承認まで編集系ツールを使わない: Codex と同じ規律になり両ホストの手順がそろう。承認前の編集を止めるのは規律だけになる
- plan mode に入り、調査とレビューの前に抜ける: 抜けた後に編集を止める仕組みが無く、mode の出入りで手順が増える

## 決定

Claude Code でも plan mode に入らない。ユーザーが承認するまで編集系のツールを使わない規律を両ホスト共通にする。

## 結果

### 良くなったこと

- auto mode のまま、プラン中の一次情報の確認と敵対的レビューが止まらずに進む

### 引き受けたコスト

- 承認前の編集を止めるのが規律だけになる

### 保留した論点

- 承認前の編集を hook で機械的に止めること。retro で観測されたら検討する
