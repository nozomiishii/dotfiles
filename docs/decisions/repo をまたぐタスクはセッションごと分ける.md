# repo をまたぐタスクはセッションごと分ける

Status: accepted
Date: 2026-07-24

## Context — 判断を迫られた状況

worktree に node_modules が無いまま commit した結果、lefthook の extends が黙って脱落し、禁止 type のコミットが commitlint をすり抜けた。構造的な原因は、セットアップがセッション開始にしか結びついておらず、セッション途中の worktree 作成・非対話シェル・cloud で環境が整わないこと。別 repo を触るとき checkout が古く手戻りする問題もあった。議論の経緯は [#1268](https://github.com/nozomiishii/dotfiles/issues/1268)。

## Decision — 決めたこと

- repo をまたぐタスクは、同一セッションで worktree を切るよりセッションごと分けるのを基本にする。worktree は最新 origin/main 起点で作る
- 環境評価の正本は各 repo にコミットする `.envrc`。対話シェルでは direnv、非対話シェル(エージェント)では agent hooks が評価する
- 必ず direnv を通す。whitelist が「自分の repo だけ実行する」信頼ゲートになるため、direnv 不在時はフォールバックせず警告して止める
- 冪等な install 系はどこで走ってもよく、git 状態を変える系(ff-only merge)は linked worktree のときだけ実行する

## Consequences — 決定がもたらすもの

- セッション途中で切った worktree でも hooks と依存が揃い、すり抜け事故が構造的に起きない
- フローの手順は wt スキルが正本として運用する
