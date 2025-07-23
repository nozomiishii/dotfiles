#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
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

echo "\n🚀 Average startup time: ${average}s over $iterations runs." 
