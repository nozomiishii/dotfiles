#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# Claude Code の利用状況レポート (/insights) を生成し、日本語に翻訳して
# ブラウザで開き、macOS 通知で知らせる。
# launchd (local.claude-insights.plist) から毎月 1 日・15 日に起動される。
#
# 配信方法は今のところ「通知 + ブラウザ自動オープン」。後でメール送信に
# 差し替える場合は、末尾の「配信」ブロックだけ入れ替えればよい。

USAGE_DIR="$HOME/.claude/usage-data"
REPORT_EN="$USAGE_DIR/report.html"
REPORT_JA="$USAGE_DIR/report.ja.html"

# 翻訳に使うモデル。68KB の HTML を「忠実コピー＋翻訳」させるタスクは出力トークン量が
# 支配的。sonnet は実測でドキュメント前半（head/CSS 含む）を脱落させ完走できず、しかも
# opus(~9 分)より遅かった(~12 分)。よって忠実に再現できる opus を既定にする。
TRANSLATE_MODEL="opus"

notify() {
  # $1: メッセージ, $2: サウンド名 (省略可)
  local sound="${2:-}"
  if [[ -n "$sound" ]]; then
    osascript -e "display notification \"$1\" with title \"Claude Code Insights\" sound name \"$sound\""
  else
    osascript -e "display notification \"$1\" with title \"Claude Code Insights\""
  fi
}

fail() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
  notify "Failed: $1 (see /tmp/claude-insights.log)" "Basso"
  exit 1
}

# ----------------------------------------------------------------
# 1. 英語レポートを生成
# ----------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - Generating insights report..."
claude -p "/insights" >/dev/null || fail "/insights generation failed"
[[ -f "$REPORT_EN" ]] || fail "report.html was not generated"

# ----------------------------------------------------------------
# 2. 日本語に翻訳
# ----------------------------------------------------------------
echo "$(date '+%Y-%m-%d %H:%M:%S') - Translating to Japanese..."
TRANSLATE_PROMPT='あなたは HTML 翻訳器です。入力 HTML の人間が読む表示テキスト（title, 見出し, 段落, ラベル, リスト項目など）だけを自然な日本語に翻訳し、それ以外（DOCTYPE, タグ, 属性, class名, <style> 内の CSS, リンクURL）は1文字も変えずに維持してください。出力は HTML 全体のみ。マークダウンのコードフェンス(```)や説明文は絶対に付けないこと。'

# 翻訳結果を一時ファイルへ。途中失敗で report.ja.html を壊さないため。
TMP_JA="$(mktemp)"
trap 'rm -f "$TMP_JA"' EXIT
# mktemp が作る既存ファイルへ書くため、noclobber (set -C) を >| で明示上書き
cat "$REPORT_EN" | claude -p --model "$TRANSLATE_MODEL" "$TRANSLATE_PROMPT" >| "$TMP_JA" || fail "translation failed"

# 安全網: 万一コードフェンスが付いた場合は剥がす
if [[ "$(head -1 "$TMP_JA")" == '```'* ]]; then
  sed -i '' -e '1d' -e '/^```$/d' "$TMP_JA"
fi

# 妥当性チェック: 翻訳結果が原文の構造を保っているか。
# モデルが途中脱落・要約すると head/CSS/サイズが欠ける（sonnet で実測）ので、
# 必須要素とサイズ下限（原文の 70%）の両方を確認し、壊れていれば原文を捨てない。
EN_SIZE=$(wc -c < "$REPORT_EN")
JA_SIZE=$(wc -c < "$TMP_JA")
grep -qi '</html>' "$TMP_JA" || fail "translation broken (no </html>)"
grep -qi '<style>' "$TMP_JA" || fail "translation broken (missing <style>, CSS dropped)"
if (( JA_SIZE * 100 < EN_SIZE * 70 )); then
  fail "translation too small (${JA_SIZE}B < 70% of source ${EN_SIZE}B), likely truncated"
fi

mv "$TMP_JA" "$REPORT_JA"
trap - EXIT

# ----------------------------------------------------------------
# 3. 配信（クリックで開く通知）
# ----------------------------------------------------------------
# terminal-notifier の通知をクリックすると既定ブラウザでレポートを開く。
# 勝手にタブを開かず、見たいときだけ開ける。
echo "$(date '+%Y-%m-%d %H:%M:%S') - Notifying..."
if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier \
    -title "Claude Code Insights" \
    -message "Your usage report is ready (click to open)" \
    -open "file://$REPORT_JA" \
    -sound Glass
else
  # フォールバック: terminal-notifier 未導入ならブラウザを直接開いて通知
  open "$REPORT_JA"
  notify "Report opened (terminal-notifier not installed)" "Glass"
fi
echo "$(date '+%Y-%m-%d %H:%M:%S') - Done."
