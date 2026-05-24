# Statusline 実装ガイド

Claude Code の statusline を編集するときの手順。

## 編集手順

### ソースを読む

- 設定: [home/.claude/settings.json](../home/.claude/settings.json) の `statusLine`
- 実装: [home/.claude/statusline.sh](../home/.claude/statusline.sh)

### 色やレイアウトを決める際の候補の出し方

`\033[32m` のような ANSI エスケープは、文字列のままでは何色か判別できないので、必ず実環境にレンダリングして見比べる。Claude が読む `~/.claude/statusline.sh` は main repo への Stow リンクで、worktree の編集は映らない。worktree で直したら main repo の `home/.claude/statusline.sh` にも入れる。

- `statusline.sh` を一時的に複数行出力にする。
- 各行に異なる色コード + ラベルを並べる。
- Claude Code を再描画して全候補を見比べる。

### PR 本文に before / after を載せる

変更確認がしやすいように、本文に修正前後の表示例を必ず書く。

例:

````markdown
## Statusline before / after

Before:

```
dotfiles[shiny-munching-rose] git:(main) !1
Opus 4.7 | 12% | surface:63 | [editor]
```

After:

```
cursor://file/Users/nozomiishii/dotfiles/.claude/worktrees/shiny-munching-rose
dotfiles[shiny-munching-rose] git:(main) !1
Opus 4.7 | 12% | surface:63
```
````

