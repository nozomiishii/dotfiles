---
name: ad
description: /a を deep research モードで実行する
argument-hint: <question>
disable-model-invocation: true
model: sonnet
---

# /ad wrapper

このコマンドは Sonnet サブエージェントで実行する。親セッションが Opus 1M でも、サブエージェントは Sonnet 標準 context で走るので Extra Usage 課金 (1M Sonnet) を踏まない。

## 質問内容

$ARGUMENTS

## 親セッションが行うこと

今すぐ Agent tool を 1 回呼ぶ。中間説明や事前確認は不要、即 dispatch する:

- `subagent_type`: `"general-purpose"`
- `model`: `"sonnet"`
- `description`: `"3社並列 deep research"`
- `prompt`: `$HOME/.agents/skills/ad/subagent.md` を Read し、本文中の `{{QUESTION}}` を上記の質問内容に置き換えた全文

サブエージェントの戻り値（各社の状態とタブ URL の一覧）をそのままユーザーに表示して終了。回答本文はチャットに流れてこない。ユーザーは提示された URL のタブで直接読む。
