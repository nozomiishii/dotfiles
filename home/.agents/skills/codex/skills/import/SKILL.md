---
name: import
description: >-
  Codex CLI / Codex App のセッション内容を現在の Claude Code セッションに引き継ぐ。
  ユーザーが /codex:import と入力したとき、または「Codex でやっていた作業の続きをやって」
  「Codex セッションを引き継いで」と言ったときに使用する。
---

# /codex:import

Codex セッション (rollout JSONL) から依頼・作業内容・残タスクを抽出し、現状と突き合わせてから続きを再開する。openai-codex plugin の /codex:transfer (Claude Code → Codex) の逆方向。

## セッションの場所

- 進行中: `~/.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<uuid>.jsonl`
- アーカイブ済み: `~/.codex/archived_sessions/`
- ファイル名の uuid がセッション id。`codex resume <uuid>` に渡せるものと同じ
- 一覧が空に見えても無いと断定しない。年/月/日のサブディレクトリ構造なので find で再帰する。sandbox の読み取り拒否でも空に見えるため、その場合は sandbox を外して再試行する

## 対象セッションの特定

本文を grep で探さない。1 行目の session_meta にグローバル AGENTS.md 全文が埋め込まれており、リポジトリ名などのキーワードが大量に誤ヒットする。1 行目の payload.cwd で絞り、新しい順に候補を出す:

```sh
for f in $(find ~/.codex/sessions ~/.codex/archived_sessions -name "*.jsonl" 2>/dev/null | sort -r); do
  head -1 "$f" | jq -r --arg f "$f" '[.payload.cwd, .payload.originator, $f] | @tsv'
done
```

実作業でないセッションを除外する:

- originator が codex_exec のもの (Claude Code の plugin やスクリプト経由の単発呼び出し)
- user_message が approval 判定・レビュー指示だけのもの (Codex の内部セッション)

候補が近接するときの「最新」は、開始時刻 (ファイル名) でなく各ファイル末尾の timestamp (`tail -1 "$f" | jq -r .timestamp`) で比べる。後から始まったセッションが先に終わっていることがある。

Codex App / Cloud 由来のセッションは cwd がローカルに存在しないパスのことがある。cwd の完全一致で見つからないときはリポジトリ名で緩く照合する。内容の裏取りで対象と確定できればそのまま進み、確定できないときだけ候補を並べてユーザーに確認する。

## 内容の抽出

MB 級のファイルがあるため丸読みしない。jq で必要な行だけ取る:

```sh
jq -r 'select(.type=="event_msg" and .payload.type=="user_message") | .payload.message + "\n---"' "$F"
jq -r 'select(.type=="event_msg" and .payload.type=="agent_message") | .payload.message' "$F" | tail -30
jq -r 'select(.type=="response_item" and .payload.type=="function_call") | .payload.name + " " + .payload.arguments[0:200]' "$F"
```

上から順に、ユーザーの依頼・Codex の報告 (末尾が最終報告と残タスク)・実行コマンド。

## 再開の前に

セッション内の「残タスク」を鵜呑みにしない。セッション終了後に PR の merge などで現状が進んでいることがある。git log・gh pr list・作業ツリーと突き合わせ、依頼・済んだこと・残り・次の一手を報告してから続きに着手する。
