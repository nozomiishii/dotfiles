---
name: ad
description: a skill を deep research モードで実行する。Claude Code では /ad、Codex では $ad で明示的に呼び出す。
argument-hint: <question>
disable-model-invocation: true
model: sonnet
---

# /ad wrapper

処理はサブエージェントへ委譲する。Claude Code では Sonnet を指定する。Codex ではモデル名を Claude Code の値から読み替えず、現在の環境で利用できる subagent を既定モデルで使う。

## 質問内容

スキルを呼び出した発話から質問部分を取り出す。質問が無ければユーザーに聞いて止まる。

## 親セッションが行うこと

今すぐ subagent を 1 つ起動する。Codex では tool 実行前の短い commentary だけを出し、不要な事前確認はしない。

Claude Code では次を指定する。Codex では invocation ごとに現在の thread ID の末尾と task 内 counter、または衝突しないランダムな小文字 hex から一意な suffix を作る。`spawn_agent` の `task_name` を `ad_research_<suffix>`、`message` を置換済みの全文にし、同じ canonical task name を再利用しない。Claude Code 固有の model パラメータは渡さない。

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"3社並列 deep research"`
- `prompt`: この SKILL.md と同じディレクトリの [subagent.md](subagent.md) を読み、本文中の `{{QUESTION}}` を上記の質問内容に置き換えた全文

サブエージェントの戻り値（各社の状態とタブ URL の一覧）をそのままユーザーに表示して終了。Codex で `login required` が返った場合は、対象サイトに Chrome でログインしてから skill を再実行するようユーザーへ依頼する。回答本文はチャットに流れてこない。ユーザーは提示された URL のタブで直接読む。
