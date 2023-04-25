#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

COMMIT_MSG_FILE=$1
COMMIT_SUBJECT=$(head -n1 "$COMMIT_MSG_FILE")
echo "$COMMIT_SUBJECT"
echo "$COMMIT_SUBJECT" | exec npx -y cspell stdin
