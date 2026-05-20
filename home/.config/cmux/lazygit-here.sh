#!/usr/bin/env bash
# cmux Dock control launcher: open lazygit on the active Claude Code worktree.
#
# Why this script exists:
#   The Dock terminal opens at the workspace cwd. For a cmux-launched
#   `claude --worktree` session that cwd is the MAIN checkout (e.g. ~/dotfiles),
#   not the worktree. Claude Code does its live edits in
#   <repo>/.claude/worktrees/<name>, so window-inherit-working-directory alone
#   never lands here. We hop to the most recently modified worktree before
#   launching lazygit so the Dock shows the diff the agent is actually editing.
#
# Heuristic: newest .claude/worktrees/<name> by mtime. Good for a single active
# agent; with several parallel agents in one repo it may pick the wrong one
# (revisit with a CMUX_WORKSPACE_ID-keyed mapping if that becomes a problem).
#
# Set LAZYGIT_HERE_DRYRUN=1 to print the resolved directory and exit (tests).

# Resolve the main checkout root (works whether cwd is the main checkout or a
# linked worktree: --git-common-dir always points at the shared .git).
if common=$(git rev-parse --git-common-dir 2>/dev/null); then
  root=$(cd "$(dirname "$common")" && pwd)
else
  root=$(pwd)
fi

target="$root"
if [ -d "$root/.claude/worktrees" ]; then
  latest=$(ls -dt "$root"/.claude/worktrees/*/ 2>/dev/null | head -n1)
  [ -n "$latest" ] && target="${latest%/}"
fi

if [ -n "${LAZYGIT_HERE_DRYRUN:-}" ]; then
  printf 'root=%s\ntarget=%s\n' "$root" "$target"
  exit 0
fi

cd "$target" || exit 1
exec lazygit
