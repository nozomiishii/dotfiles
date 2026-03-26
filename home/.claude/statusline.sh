#!/bin/bash
# Claude Code statusline: show cmux surface ref for cross-pane communication

surface_ref=$(cmux identify 2>/dev/null | jq -r '.caller.surface_ref // empty' 2>/dev/null)

if [ -n "$surface_ref" ]; then
  printf '\033[1;34m[%s]\033[0m' "$surface_ref"
fi
