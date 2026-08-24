# Statusline 実装ガイド

Claude Code の statusline を編集するときの手順。

## ソースの場所

- 設定: [home/.claude/settings.json](../home/.claude/settings.json) の `statusLine`
- 実装: [home/.claude/statusline.sh](../home/.claude/statusline.sh)

```text
~/.claude/statusline.sh
  └─ dotfiles リンク → main repo の home/.claude/statusline.sh   ← Claude が読むのはここ

worktree の home/.claude/statusline.sh                       ← Claude からは見えない
```

worktree で直したら main repo にも入れる。

## 色やレイアウトの候補を見比べる

`\033[32m` のような ANSI エスケープは、文字列のままでは何色か判別できない。実環境にレンダリングして見比べる。

- `statusline.sh` を一時的に複数行出力にする
- 各行に異なる色コードとラベルを並べる
- Claude Code を再描画して全候補を見比べる

## PR 本文に before / after を載せる

本文に修正前後の表示例を必ず書く。

````markdown
## Statusline before / after

Before:

```
dotfiles[shiny-munching-rose] git:(main) !1
Opus 4.7 | 12% | [editor]
```

After:

```
cursor://file/Users/nozomiishii/dotfiles/.claude/worktrees/shiny-munching-rose
dotfiles[shiny-munching-rose] git:(main) !1
Opus 4.7 | 12%
```
````
