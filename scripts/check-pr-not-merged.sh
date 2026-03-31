#!/usr/bin/env bash
#
# check-pr-not-merged.sh - Block push to branches with MERGED/CLOSED PRs
#
# Prevents accidental pushes to branches whose pull request has already
# been merged or closed. Skips gracefully when gh CLI is unavailable,
# unauthenticated, or no PR exists for the current branch.
#
# Usage:
#   bash scripts/check-pr-not-merged.sh   # lefthook (pre-push)
#
set -euo pipefail

# Skip if gh CLI is not installed
if ! command -v gh &>/dev/null; then
  exit 0
fi

# Skip if gh is not authenticated
if ! gh auth status &>/dev/null; then
  exit 0
fi

# Get current branch name
branch=$(git branch --show-current)

# Skip on detached HEAD
if [ -z "$branch" ]; then
  exit 0
fi

# Skip on default branches
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  exit 0
fi

# Check PR state for this branch
state=$(gh pr view --json state --jq '.state' 2>/dev/null) || exit 0

if [ "$state" = "MERGED" ] || [ "$state" = "CLOSED" ]; then
  echo "ERROR: PR for branch '$branch' is already $state."
  echo ""
  echo "Create a new branch for additional changes:"
  echo "  git checkout -b <new-branch> origin/main"
  exit 1
fi
