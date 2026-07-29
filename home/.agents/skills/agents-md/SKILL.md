---
name: agents-md
description: >-
  グローバル指示ファイル AGENTS.md とスキル群の定期メンテナンスの正本。
  Claude Code で /agents-md、Codex で $agents-md と入力したとき、または
  「AGENTS.md をメンテしたい」「ルールを整理したい」「指示ファイルが肥大化してきた」
  と言ったときに使用する。
---

# /agents-md

`dotfiles/home/AGENTS.md` (`~/.claude/CLAUDE.md` の実体) とスキル群を手入れし、短く・具体的・矛盾なしに保つ。指示ファイルはコンテキストであって強制設定ではなく、長くなるほど遵守率が下がる ([Claude Code memory](https://code.claude.com/docs/en/memory))。dotfiles 以外で始まったセッションから発動した場合は、sibling の [wt SKILL.md](../wt/SKILL.md) に従って dotfiles の作業環境を用意する。

## 絶対制約

- 候補一覧の承認より前に AGENTS.md やスキルを編集しない。「整理して反映まで進めて」という依頼でも一覧の提示を省略しない。
- 統合・退避で規則の意味が変わる・狭まる場合は、候補のその行に明記する。黙って意味を変えない。
- 矛盾は解決方向を自分で決めず、選択肢としてユーザーに出す。

確認不要と明示されている場合も候補一覧は提示する。その場合だけ、承認を待たず同じターンで反映してよい。

## 判定

AGENTS.md の各ルールに順に問う。

- 消しても挙動が変わらないか。変わらないなら削除候補。試問は公式の "Would removing this cause Claude to make mistakes? If not, cut it" ([best practices](https://code.claude.com/docs/en/best-practices))
- 同趣旨のルールが他の行に無いか。あれば統合候補
- 特定の作業のときだけ必要か。そうならスキルへの退避候補。既存スキルの description・本文と突き合わせ、正本が既にスキル側にあるなら AGENTS.md 側は削除か 1 行ポインタにする
- 複数ステップの手続きになっていないか。なっていればスキル化候補
- 他のルール・スキルと矛盾していないか

ファイル全体では 200 行以下 ([Claude Code の推奨](https://code.claude.com/docs/en/memory)) と、合計 32 KiB 以下 ([Codex の読み込み上限](https://developers.openai.com/codex/guides/agents-md)) を確認する。

## 守られないルールの扱い

破られた実績のあるルールは、文面の言い換えでなく仕組みを変える。

- 公式に有効とされる強調 (IMPORTANT など) を付ける ([best practices](https://code.claude.com/docs/en/best-practices))。効果が薄れるため同時に 2-3 個まで
- ツール呼び出しを経由する違反は、PreToolUse hook の deny で機械的に止める ([Claude Code](https://code.claude.com/docs/en/hooks) / [Codex](https://learn.chatgpt.com/docs/hooks))
- それでも守られないなら、常時ルールとして適切かを疑い、スキル退避や削除を検討する

## 手順

- home/AGENTS.md の全行と、home/.agents/skills/ 配下の全 description を読む。判定に必要なスキルは本文まで読む
- 候補を番号つき表で 1 回だけ提示する。列: 番号 / 対象ルール / 種別 (削除・統合・退避・スキル化・矛盾・強調) / 提案 / 意味の変化
- 「2 と 4 だけ」のような番号での取捨選択、修正指示を反映して実行する
- スキルの新規作成・編集を伴う候補は、sibling の [skill SKILL.md](../skill/SKILL.md) に従う
- 反映後、移した各ルールが正本 1 箇所にだけあることを grep で確認し、前後の行数を報告する
- PR を作成し、sibling の [cloud-bump SKILL.md](../cloud-bump/SKILL.md) でマージ後の bump 要否を判定して予告する

## 実行の目安

- AGENTS.md へのルール追加が続いた後
- ルールが守られない事象が続いたとき
- 前回のメンテから半年経ったとき
