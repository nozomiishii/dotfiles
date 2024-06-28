#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open url - compass.com
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔗
# @raycast.packageName System

# Documentation:
# @raycast.description This script opens the url of compass.com
# @raycast.author Nozomi Ishii
# @raycast.authorURL https://github.com/nozomiishii

# -C          : Prevent overwriting existing files when redirecting output.
#               - Helps to avoid accidentally overwriting files when using
#                 redirection operators like > or >> in the script.
# -e          : Exit the script if any command returns a non-zero status.
#               - Ensures the script stops on the first error encountered.
# -u          : Exit the script if an undefined variable is used.
#               - Prevents running commands with unintended variables.
# -o pipefail : Change pipeline exit status to the last non-zero exit code
#               in the pipeline, or zero if all commands succeed.
#               - Ensures proper error handling in pipelines.
# -x          : (Optional) Enable command tracing for easier debugging.
#               - Uncomment this option to debug the script.
set -Ceuo pipefail

city_name="大阪"
current_date=$(date "+%Y/%m/%d")

url="https://connpass.com/search/?q=$city_name&start_from=$current_date"

open "$url"
