#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

iterations="${1:-10}"

shell_path="${SHELL:-/bin/zsh}"

echo "🕒 Measuring startup time for $shell_path ($iterations runs)"

total=0
for i in $(seq 1 "$iterations"); do
  # Capture only the \"real\" time reported by POSIX time (-p)
  run_time=$( { time -p "$shell_path" -i -c exit > /dev/null; } 2>&1 | awk '/^real/ {print $2}' )
  echo "Run $i: ${run_time}s"
  # Accumulate using bc for floating-point support
  total=$( echo "$total + $run_time" | bc -l )
  # Short pause between runs to avoid side-effects (optional)
  sleep 0.1
done

average=$( echo "scale=3; $total / $iterations" | bc -l )

printf "\n🚀 Average startup time: %ss over %s runs.\n" "$average" "$iterations"
