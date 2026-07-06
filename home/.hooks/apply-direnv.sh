#!/usr/bin/env bash
#
# apply-direnv.sh - エージェントのセッションで .envrc を評価する
#
# Claude Code / Codex の Bash tool は非対話シェルで、direnv の prompt hook が
# 発火しない。このスクリプトを SessionStart / CwdChanged hook から呼び、
# 対話シェルで direnv がやることを非対話シェルで再現する。
# 設計の経緯: https://github.com/nozomiishii/dotfiles/issues/1268
#
# 失敗してもセッションは止めない。
set -uo pipefail

env_exports=""
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""

if [ -n "$root" ] && [ -f "$root/.envrc" ]; then
  if command -v direnv >/dev/null 2>&1; then
    cd "$root" || exit 0
    # 信頼ゲート: whitelist / allow 済みでない .envrc は評価されず空が返る。
    # 素の bash 実行は他人の repo の .envrc まで無条件実行してしまうため必ず direnv を通す。
    # blocked や評価エラーの stderr は捨てずに hook のログへ流す (静かな劣化防止)。
    # export bash は .envrc を評価する (副作用も走る) と同時に env の export 文を吐く。
    env_exports=$(direnv export bash) || env_exports=""
  else
    echo "apply-direnv: direnv not found; skipped $root/.envrc" >&2
  fi
fi

# Claude Code のみ env をセッションに注入する (Codex は CLAUDE_ENV_FILE が無く、
# direnv export 時の副作用だけ走る)。
# CLAUDE_ENV_FILE は append-only の公式仕様のため、スナップショットへの間接参照
# 1 行だけを追記し、スナップショット側を毎回上書きする。.envrc の無い場所へ移動した
# ときは空で上書きされ、前の repo の env が次のシェルから消える (direnv の unload 相当)。
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  snapshot="${CLAUDE_ENV_FILE}.envrc-snapshot"
  # 末尾の true は direnv export の出力が `;` で終わり `;&&` 構文エラーになるのを防ぐ
  printf '%s\ntrue\n' "$env_exports" >"$snapshot"
  grep -qF "$snapshot" "$CLAUDE_ENV_FILE" 2>/dev/null ||
    echo ". \"$snapshot\"" >>"$CLAUDE_ENV_FILE"
fi

exit 0
