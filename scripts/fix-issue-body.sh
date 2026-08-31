#!/usr/bin/env bash
#
# fix-issue-body.sh - 1行に潰れた GitHub issue 本文の修復
#
# routine が作る issue は、実改行の代わりにリテラルの `\n`
# (バックスラッシュ + n の2文字) を並べた1行文字列で投稿されることがある。
# stdin で受け取った本文がその壊れ方をしていたら、実改行へ戻して stdout に出す。
#
# 判定は「実改行が MAX_NEWLINES 以下」かつ「実改行に戻せるリテラルの `\n` が
# MIN_ESCAPES 個以上」。`\\n` はエスケープされたバックスラッシュ + n であって
# 改行の指示ではないので、数にも変換にも入れない。
#
# 終了コードで呼び出し側に伝える:
#   0 - 壊れていたので修復した。修復後の本文を stdout に出す
#   1 - 壊れていない。修復不要。stdout には何も出さない
#   2 - 想定外の失敗。修復してよいかを判断できていない
#
# GitHub API には触れない。判定と変換だけを行うテキストフィルタ。
#
# Usage:
#   gh issue view 123 --json body -q .body | bash scripts/fix-issue-body.sh
#
set -euo pipefail

# 「壊れていない」の 1 に紛れないよう、想定外の失敗は 2 に寄せる
trap 'exit 2' ERR

readonly MAX_NEWLINES=1
readonly MIN_ESCAPES=3

newline=$'\n'
escape='\n'               # バックスラッシュ + n の2文字
escaped_backslash=$'\\\\' # バックスラッシュ2文字

# コマンド置換は末尾の改行を落とすので、目印の x を付けてから剥がす
body=$(cat; printf 'x')
body=${body%x}

# 出現回数は「取り除く前後の長さの差 / 1回分の長さ」で数える
without_newlines=${body//"$newline"/}
newline_count=$((${#body} - ${#without_newlines}))

# `\\` を落としてから数える。変換も `\\` を退避してから行うので、ここで数えた
# 個数がそのまま実改行に戻る個数になる
unescaped=${body//"$escaped_backslash"/}
without_escapes=${unescaped//"$escape"/}
escape_count=$(((${#unescaped} - ${#without_escapes}) / ${#escape}))

if [ "$newline_count" -gt "$MAX_NEWLINES" ] || [ "$escape_count" -lt "$MIN_ESCAPES" ]; then
  exit 1
fi

# `\\n` のバックスラッシュを実改行に化けさせないため、先に `\\` を退避する。
# 退避先は本文に1文字も出てこない制御文字を選ぶ。本文にある文字を使うと、
# 元からあった文字と退避した目印の区別が付かず、書き戻しで位置がずれる。
placeholder=''
for candidate in $'\001' $'\002' $'\003' $'\004' $'\005'; do
  if [[ $body != *"$candidate"* ]]; then
    placeholder=$candidate
    break
  fi
done

if [ -z "$placeholder" ]; then
  echo "ERROR: every placeholder character occurs in the body. Leaving it untouched." >&2
  exit 2
fi

body=${body//"$escaped_backslash"/"$placeholder"}
body=${body//"$escape"/"$newline"}
body=${body//"$placeholder"/"$escaped_backslash"}

printf '%s' "$body"
