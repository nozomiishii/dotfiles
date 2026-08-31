#!/usr/bin/env bash
#
# fix-issue-body.test.sh - fix-issue-body.sh の単体テスト
#
# bash だけで完結する。外部のテストランナーは使わない。
# 失敗したケースがあれば期待値と実際値を出して exit 1 で終わる。
#
# Usage:
#   bash scripts/fix-issue-body.test.sh
#
set -uo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target="$script_dir/fix-issue-body.sh"

failures=0
total=0

# 1ケース分の stdin を流し、終了コードと stdout を期待値と照合する。
# 検証するのは呼び出し側が使う終了コードと stdout の2つ。stderr は人間向けの
# 補足なので捨てる。末尾の改行がコマンド置換で落ちないよう、目印の x で挟む。
assert_filter() {
  local title=$1 stdin=$2 want_status=$3 want_stdout=$4
  local marked got_stdout got_status

  total=$((total + 1))

  marked=$(printf '%s' "$stdin" | bash "$target" 2>/dev/null; status=$?; printf 'x'; exit "$status")
  got_status=$?
  got_stdout=${marked%x}

  if [ "$got_status" -eq "$want_status" ] && [ "$got_stdout" = "$want_stdout" ]; then
    printf 'ok   %s\n' "$title"
    return
  fi

  failures=$((failures + 1))
  printf 'FAIL %s\n' "$title"
  printf '  want: status=%d stdout=%q\n' "$want_status" "$want_stdout"
  printf '  got : status=%d stdout=%q\n' "$got_status" "$got_stdout"
}

# 1行に潰れた本文は、リテラルの \n が実改行に戻る
assert_filter 'converts a collapsed one-line body into real newlines' \
  '# 日報\n\n## やったこと\n\n- 実装\n- レビュー\n' \
  0 \
  '# 日報

## やったこと

- 実装
- レビュー
'

# 実改行で書かれた正常な本文は修復対象にならない
assert_filter 'leaves a healthy multi-line body untouched' \
  '# 日報

## やったこと

- 実装
- レビュー
' \
  1 \
  ''

# inline code のリテラル \n を壊れた本文と誤検出しない
# backtick を渡すため二重引用符にする。\n は二重引用符でもそのまま2文字で残る
assert_filter 'does not flag literal escapes inside inline code of a multi-line body' \
  "# メモ

改行は \`\n\` で表す。

- \`\n\` は LF
- \`\r\n\` は CRLF
" \
  1 \
  ''

# 実改行ちょうど1・リテラル \n ちょうど3 は壊れている側に倒す (境界)
assert_filter 'treats one real newline with exactly three escapes as broken' \
  '# Title\n\n- A\n
' \
  0 \
  '# Title

- A

'

# 実改行が2以上あれば、リテラル \n がいくつ並んでいても修復しない。
# 一部のセクションだけ潰れた本文は検出の対象外という閾値の固定
assert_filter 'leaves a partially collapsed body untouched' \
  '# 日報

## やったこと\n\n- 実装\n- レビュー

## 明日やること
' \
  1 \
  ''

# リテラル \n が閾値未満なら1行でも修復しない
assert_filter 'leaves a one-line body with only two escapes untouched' \
  'ひとことメモ\n続き\n' \
  1 \
  ''

# エスケープされたバックスラッシュに続く n は改行の指示ではない。
# \\n しか無い1行本文は、実改行に戻すものが無いので修復対象にならない
assert_filter 'does not count an escaped backslash followed by n as a newline escape' \
  'メモ\\nメモ\\nメモ\\n' \
  1 \
  ''

# 修復済みの本文をもう一度通しても対象にならない (冪等性)
repaired=$(printf '%s' '# 日報\n\n## やったこと\n\n- 実装\n- レビュー\n' | bash "$target")
assert_filter 'does not repair an already repaired body' \
  "$repaired" \
  1 \
  ''

# \\n のバックスラッシュを実改行に化けさせない
assert_filter 'keeps an escaped backslash from turning into a newline' \
  '# メモ\n\nコードでは \\n と書く\n以上\n' \
  0 \
  '# メモ

コードでは \\n と書く
以上
'

# 退避に使う制御文字が本文に居ても、その文字と \\ の位置が入れ替わらない
placeholder_in_body=$'\001'
assert_filter 'keeps text intact when a placeholder character sits next to an escaped backslash' \
  '# メモ\n\n手順 '"$placeholder_in_body"'\\n を残す\n以上\n' \
  0 \
  '# メモ

手順 '"$placeholder_in_body"'\\n を残す
以上
'

# 退避先に使える文字が本文で埋まったら、黙って壊さずエラーで落ちる
all_placeholders=$'\001\002\003\004\005\006\007\010'
assert_filter 'fails with exit 2 when no placeholder character is free' \
  '# メモ'"$all_placeholders"'\n\n- A\n- B\n' \
  2 \
  ''

# 引き受けた偽陽性: 1行に収まる健全な本文でも、inline code のリテラル \n が
# 閾値に届けば書き換わる。検出では区別できないので現在の挙動を固定しておく
assert_filter 'rewrites a healthy one-line body that merely mentions three escapes' \
  "エスケープの例: \`\n\` \`\n\` \`\n\`" \
  0 \
  "エスケープの例: \`
\` \`
\` \`
\`"

# 空本文は修復対象にならない
assert_filter 'leaves an empty body untouched' \
  '' \
  1 \
  ''

printf '\n%d passed, %d failed, %d total\n' "$((total - failures))" "$failures" "$total"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
