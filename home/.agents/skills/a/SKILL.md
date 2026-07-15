---
name: a
description: ChatGPT・Claude・Geminiに同じ質問を並列投下して回答を比較
argument-hint: <question>
disable-model-invocation: true
model: sonnet
---

# /a wrapper

このコマンドは Sonnet サブエージェントで実行する。親セッションが Opus 1M でも、サブエージェントは Sonnet 標準 context で走るので、Extra Usage 課金 (1M Sonnet) を踏まずに高速・低コストで処理できる。

送信直後にタブ URL をユーザー画面に出すため、2 段階で dispatch する。親セッションの仕事は下記 2 回の dispatch と結果表示だけ。中間説明や事前確認はしない。

## 質問内容

$ARGUMENTS

## Stage 1: タブ準備 + 質問送信

`$HOME/.agents/skills/a/stage1.md` を Read し、本文中の `{{QUESTION}}` を上記の質問内容に置き換えた全文を prompt にして Agent tool を呼ぶ:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"/a stage 1 (setup + send)"`

Stage 1 は JSON 1 行を返す。parse して、以下のフォーマットでユーザーに直接表示する（これが「送信直後の URL 表示」になる）:

```
送信完了。各タブの URL:
- ChatGPT: <chatgpt_url>
- Claude: <claude_url>
- Gemini: <gemini_url>
```

`error` フィールドがあれば素直に伝える（ログイン要求・サイトスキップ等）。3 URL すべて `null` なら Stage 2 をスキップして終了。

## Stage 2: ポーリング + レポート

URL 表示の直後、`$HOME/.agents/skills/a/stage2.md` を Read し、本文中の `{{QUESTION}}` を質問内容に、`{{CHATGPT_URL}}` `{{CLAUDE_URL}}` `{{GEMINI_URL}}` を Stage 1 で得た値に置き換えた全文を prompt にして Agent tool を呼ぶ:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"/a stage 2 (poll + report)"`

Stage 1 の `error` に `"gemini fast fallback"` が含まれていた場合は、置換後の prompt 末尾に `Stage 1 の error: gemini fast fallback (pro switch failed)` の 1 行を足す。

Stage 2 の戻り値（最終レポート markdown）をそのままユーザーに表示して終了。
