---
status: accepted
date: 2026-07-24
---

# repo をまたぐタスクはセッションごと分ける

## 背景と課題

worktree で commit したときに、次が起きた。

```text
worktree に node_modules が無い
  → lefthook の extends が黙って脱落
  → 禁止 type のコミットが commitlint をすり抜ける
```

構造的な原因は、セットアップがセッション開始にしか結びついておらず、セッション途中の worktree 作成・非対話シェル・cloud で環境が整わないこと。別 repo を触るとき checkout が古く手戻りする問題もあった。議論の経緯は [#1268](https://github.com/nozomiishii/dotfiles/issues/1268)。

## 検討した選択肢

### repo をまたぐタスクの進め方

| 選択肢 | 評価 |
| --- | --- |
| 同一セッションで worktree を切る | セットアップがセッション開始にしか結びついていないため、途中で切った worktree では環境が整わない |
| セッションごと分ける | セッション開始のセットアップが走る。worktree を最新 origin/main 起点で作れる |

### direnv が無いときの扱い

| 選択肢 | 評価 |
| --- | --- |
| フォールバックして評価する | whitelist の信頼ゲートを外れて評価が走る |
| 警告して止める | whitelist が「自分の repo だけ実行する」信頼ゲートとして働く |

## 決定

- repo をまたぐタスクは、同一セッションで worktree を切るよりセッションごと分けるのを基本にする。worktree は最新 origin/main 起点で作る
- 環境評価の正本は各 repo にコミットする `.envrc`。対話シェルでは direnv、非対話シェル (エージェント) では agent hooks が評価する
- 必ず direnv を通す。direnv 不在時はフォールバックせず警告して止める
- 冪等な install 系はどこで走ってもよく、git 状態を変える系 (ff-only merge) は linked worktree のときだけ実行する

## 結果

### 良くなったこと

- セッション途中で切った worktree でも hooks と依存が揃い、すり抜け事故が構造的に起きない
- フローの手順は wt スキルが正本として運用する

### 引き受けたコスト

なし

### 保留した論点

なし
