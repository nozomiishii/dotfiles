---
name: wt
description: >-
  git worktree を最新の origin/main 起点で作り、.envrc を評価して開発可能な状態で渡す。
  ユーザーが /wt と入力したとき、セッション開始ディレクトリ以外の repo を変更するとき、
  またはスキルや作業フローが作業用 worktree を必要とするときに使用する。
---

# /wt

worktree を「最新の origin/main 起点 + 依存 install 済み」で用意する。設計の経緯は [dotfiles#1268](https://github.com/nozomiishii/dotfiles/issues/1268)。

## 手順

REPO は対象 repo のルート。SLUG はブランチ名で、呼び出し元の規約に従う (無ければ作業内容の kebab-case)。

```sh
git -C "$REPO" fetch origin main --quiet
WT="$REPO/.claude/worktrees/$SLUG"
git -C "$REPO" worktree add "$WT" -b "$SLUG" origin/main
direnv exec "$WT" true
```

- direnv exec が worktree の .envrc を評価し、依存 install まで済ませる。エージェントの非対話シェルでは direnv が自動発火しないため、作成直後の明示実行が必須。cd せず `git -C` で操作し続ける場合、これを飛ばすと lefthook 等が黙って壊れたまま気づけない
- .envrc の無い repo でも direnv exec は無害に通る
- REPO が無い cloud セッションでは、`~/Code/<owner>/<repo>` の規約で owner/repo を導出して add_repo し、clone 先を REPO とする。呼び出し元の依頼を add_repo の明示的な依頼として扱い、承認が要る場合は得られるまで待つ。REPO を用意せずに一時ディレクトリなど代替の置き場へ進まない
- 後続の commit / push / PR の規約は呼び出し元 (スキルや会話) に従う
