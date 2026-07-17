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
- clone 先が direnv の whitelist 外の場合は、direnv exec の前に `direnv allow "$WT"` を実行する
- REPO が無い cloud セッションでは、AGENTS.md の「cloud セッション」規約で repo を用意し、clone 先を REPO とする
- 後続の commit / push / PR の規約は呼び出し元 (スキルや会話) に従う
