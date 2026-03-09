#!/bin/bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="${SCRIPT_DIR}/../../Brewfile"

# ----------------------------------------------------------------
# Utils
# ----------------------------------------------------------------
request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  echo -e "- 👨🏻‍🚀 Please enter your password to grant sudo access for this operation"
  sudo -v

  # Temporarily increase sudo's timeout until the process has finished
  (
    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" || exit
    done
  ) 2> /dev/null &
}

# Retry brew bundle to tolerate transient cask download failures (e.g. CDN).
# Uses HOMEBREW_CURL_RETRIES for per-download retries and an outer retry loop with backoff.
retry_brew_bundle() {
  local max_attempts="${BREW_BUNDLE_MAX_ATTEMPTS:-5}"
  local attempt=1
  local backoff_base="${BREW_BUNDLE_BACKOFF_SEC:-20}"

  while [ "$attempt" -le "$max_attempts" ]; do
    echo "brew bundle attempt ${attempt}/${max_attempts}"
    if HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}" brew bundle --verbose --file="$BREWFILE"; then
      echo "brew bundle succeeded"
      return 0
    fi
    if [ "$attempt" -eq "$max_attempts" ]; then
      echo "brew bundle failed after ${max_attempts} attempts"
      return 1
    fi
    sleep "$((backoff_base * attempt))"
    attempt="$((attempt + 1))"
  done
  return 1
}

request_admin_privileges

# ----------------------------------------------------------------
# Homebrew - Install
# ----------------------------------------------------------------
echo -e "Initializing Homebrew setup..."

# For Intel mac
if [ "$(uname -m)" = "x86_64" ]; then
  if ! command -v brew > /dev/null 2>&1; then
    echo "- 🍺 brew doesn't exist, continuing with install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
# For M1 mac
elif [ "$(uname -m)" = "arm64" ]; then
  if ! command -v brew > /dev/null 2>&1; then
    echo '- 🍺 Install Rosetta 2'
    sudo softwareupdate --install-rosetta --agree-to-license

    echo "- 🍺 brew doesn't exist, continuing with install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

export HOMEBREW_CASK_OPTS="--no-quarantine --appdir=~/Applications"

retry_brew_bundle

# ----------------------------------------------------------------
# Homebrew - Cleanup
# ----------------------------------------------------------------
# Uninstall packages not listed in the merged Brewfile, with details on what is being removed
brew bundle cleanup --verbose --force --file="$BREWFILE"

# Remove outdated versions of installed packages and unnecessary files to free up disk space
brew cleanup --verbose
brew upgrade --verbose

echo -e "🍺 Homebrew setup is complete 🎉"
