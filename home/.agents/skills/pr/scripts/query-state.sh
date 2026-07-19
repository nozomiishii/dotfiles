#!/usr/bin/env bash

set -euo pipefail

if (($# != 4)); then
  printf 'usage: %s <owner> <repo> <pr-number> <state-dir>\n' "$0" >&2
  exit 2
fi

OWNER=$1
NAME=$2
NUM=$3
STATE_DIR=$4
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
QUERY_FILE="$SCRIPT_DIR/../state-query.graphql"

[[ "$OWNER" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,38}$ && "$OWNER" != *- ]] || {
  printf 'invalid owner: %s\n' "$OWNER" >&2
  exit 2
}

[[ "$NAME" =~ ^[A-Za-z0-9._-]+$ && "$NAME" != '.' && "$NAME" != '..' ]] || {
  printf 'invalid repo: %s\n' "$NAME" >&2
  exit 2
}

[[ "$NUM" =~ ^[1-9][0-9]*$ ]] || {
  printf 'invalid PR number: %s\n' "$NUM" >&2
  exit 2
}

STATE_PREFIX="/tmp/agent-pr-state-$(id -u)."
STATE_SUFFIX=${STATE_DIR#"$STATE_PREFIX"}
[[ "$STATE_DIR" == "$STATE_PREFIX"* && "$STATE_SUFFIX" =~ ^[A-Za-z0-9]{6}$ ]] || {
  printf 'invalid state directory: %s\n' "$STATE_DIR" >&2
  exit 2
}

[[ -d "$STATE_DIR" && ! -L "$STATE_DIR" && -O "$STATE_DIR" ]] || {
  printf 'state directory must be an owned, real directory: %s\n' "$STATE_DIR" >&2
  exit 2
}

if STATE_MODE=$(stat -c '%a' "$STATE_DIR" 2>/dev/null); then
  :
elif STATE_MODE=$(stat -f '%Lp' "$STATE_DIR" 2>/dev/null); then
  :
else
  printf 'cannot inspect state directory mode: %s\n' "$STATE_DIR" >&2
  exit 2
fi

[[ "$STATE_MODE" == 700 ]] || {
  printf 'state directory must have mode 700: %s has %s\n' "$STATE_DIR" "$STATE_MODE" >&2
  exit 2
}

[ -r "$QUERY_FILE" ] || {
  printf 'query file is not readable: %s\n' "$QUERY_FILE" >&2
  exit 1
}

TMP_STATE=$(mktemp "$STATE_DIR/state.XXXXXX")
trap 'rm -f -- "$TMP_STATE"' EXIT HUP INT TERM

gh api graphql \
  -F owner="$OWNER" -F name="$NAME" -F number="$NUM" \
  -F query=@"$QUERY_FILE" \
  --jq '.data.repository.pullRequest' > "$TMP_STATE"

chmod 600 "$TMP_STATE"
mv -f -- "$TMP_STATE" "$STATE_DIR/state.json"
trap - EXIT HUP INT TERM
