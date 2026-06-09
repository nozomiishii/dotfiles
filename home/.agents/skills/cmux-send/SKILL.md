---
name: cmux-send
description: >-
  隣の cmux ペインにコンテキスト（テキスト情報）を送信する。
  ユーザーが「隣のペインに送って」「他のセッションに共有して」「/cmux-send」などと言ったときに使用する。
  引数の数字は surface ref の省略形（例: 1 = surface:1）。
---

# cmux ペイン間コンテキスト送信

隣の cmux ペインで動作中の Claude Code セッションにコンテキストを送信する。

## 引数

- `/cmux-send 11` → surface:11 に送信
- `/cmux-send` → 送信先一覧を表示してユーザーに選んでもらう

数字はそのまま surface ref の番号として扱う（`11` = `surface:11`）。

## 手順

### 1. 自分の surface を特定する

```bash
cmux identify
```

`caller.surface_ref` が自分の surface。

### 2. 送信先を決定する

引数に番号がある場合は `surface:<番号>` を送信先にする。

引数がない場合は、自分以外のペインを列挙する:

```bash
cmux list-panes
# 自分以外の各 pane について
cmux list-pane-surfaces --pane <pane_ref>
```

- 自分以外の surface が **1 つだけ** → 確認なしでその surface に送る
- **2 つ以上** → 一覧を提示してユーザーに選んでもらう

### 3. 送信先の状態を確認する

```bash
cmux read-screen --surface <target_surface_ref> --lines 5
```

Claude Code のプロンプト（`❯` や `›`）が表示されていれば送信可能。

### 4. コンテキストを一時ファイルに書き出す

```bash
cat > "$TMPDIR/cmux-context-$(date +%s).md" <<'CONTEXT'
（送信したい内容をここに書く）
CONTEXT
```

### 5. 送信する

```bash
cmux send --surface <target_surface_ref> '隣のペインからコンテキストが届いています。次のファイルを読んでください: /path/to/file.md'
```

**重要:** `\n` は Enter として送信される。ユーザーが「送って」と明示した場合のみ末尾に `\n` を付ける。確認が必要な場合は `\n` を付けずに送り、ユーザーに Enter を委ねる。
