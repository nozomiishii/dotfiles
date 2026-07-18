#!/usr/bin/env bash
#
# setup.sh - セッション開始時に repo を開発可能な状態にする
#
# .claude/settings.json と .codex/hooks.json の SessionStart hook から冪等に
# 呼ばれる。worktree を後から用意した場合はスキルの手順 (/wt, /broadcast) が
# 明示実行する。設計の経緯: https://github.com/nozomiishii/dotfiles/issues/1268
#
# .envrc の env 注入はここでは扱わない。env に依存するコマンドは
# `direnv exec . <コマンド>` で実行する (AGENTS.md の実装ルール)。
#
# worktree の起点の鮮度もここでは扱わない。Claude Code v2.1.208+ が
# origin/HEAD 起点で worktree を作り、必要な fetch も本体が行う。
# https://code.claude.com/docs/en/worktrees#choose-the-base-branch
#
# 失敗してもセッションは止めない。
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -z "$root" ]; then
  exit 0
fi
cd "$root" || exit 0

# commit 時の lefthook 等が node_modules/.bin を呼ぶため、
# 入っていないと hook が黙って壊れる。
if [ ! -d node_modules ]; then
  pnpm install
fi

exit 0
