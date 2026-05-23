#!/usr/bin/env bash
set -euo pipefail

# /insights のレポートを生成 → 日本語訳 → クリックで開く通知。
# launchd (local.claude-insights.plist) から毎月 1・15 日に起動される。

# claude は ~/.local/bin にあり、PATH へ追加するのは zsh の .zshrc だけ。
# launchd の login bash には入らないので明示的に補う。
export PATH="$HOME/.local/bin:$PATH"

REPORT="$HOME/.claude/usage-data/report.html"
REPORT_JA="$HOME/.claude/usage-data/report.ja.html"

notify() { terminal-notifier -title "Claude Code Insights" -message "$1" "${@:2}"; }
fail() { echo "$1" >&2; notify "Failed: $1" -sound Basso || true; exit 1; }

# 1. 英語レポート生成。古い report を消してから生成し、/insights が no-op でも
#    stale なレポートを掴まないようにする。
rm -f "$REPORT"
claude -p "/insights" >/dev/null || fail "/insights generation failed"
[[ -f "$REPORT" ]] || fail "report.html was not generated"

# 2. 日本語訳。68KB を忠実コピー＋翻訳するタスクは sonnet だと前半脱落するので opus 固定。
PROMPT='HTML の表示テキスト（見出し・本文・ラベル等）だけを自然な日本語に訳し、タグ/CSS/属性/URL/数値は1文字も変えないこと。HTML 全体のみ出力し、コードフェンスや説明文は付けない。'
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
claude -p --model opus "$PROMPT" >"$TMP" <"$REPORT" || fail "translation failed"

# 翻訳の破損チェック（前半脱落・要約を弾く）: HTML で始まり、原文の 70% 以上のサイズ。
head -1 "$TMP" | grep -qiE '^[[:space:]]*<(!doctype|html)' || fail "translation looks broken (not HTML)"
(( $(wc -c <"$TMP") * 10 >= $(wc -c <"$REPORT") * 7 )) || fail "translation too small (truncated?)"
mv "$TMP" "$REPORT_JA"
trap - EXIT

# 3. 通知。クリックで既定ブラウザにレポートを開く。
notify "Your usage report is ready (click to open)" -open "file://$REPORT_JA" -sound Glass
