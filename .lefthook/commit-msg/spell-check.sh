#!/bin/bash
set -Ceu

COMMIT_MSG_FILE=$1
COMMIT_SUBJECT=$(head -n1 "$COMMIT_MSG_FILE")
echo "$COMMIT_SUBJECT"
echo "$COMMIT_SUBJECT" | exec npx -y cspell stdin
