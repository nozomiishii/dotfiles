#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: scripts/homebrew.sh supports macOS only." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# CI 環境でのみ brew link の競合を修復する。
# GitHub Actions の macOS ランナーはイメージビルド時に Homebrew パッケージを
# プリインストールしているが、その後 Homebrew リポジトリに新バージョンが
# リリースされると、イメージに焼き込まれた旧バージョンの残骸ファイルが
# /opt/homebrew/ に残ったまま brew upgrade / brew bundle が走り、brew link が
# "already exists" で失敗する。
# ローカル環境では Homebrew が一貫してパッケージを管理しているためこの問題は発生しない。
# ref: https://github.com/nozomiishii/dotfiles/pull/725
fix_brew_link_conflicts() {
  if [ "${CI:-false}" != "true" ]; then
    return 0
  fi
  echo "Fixing brew link conflicts on CI..."
  for formula in $(brew list --formula); do
    brew link --overwrite "$formula" 2>/dev/null || true
  done
}

trust_brew_bundle_formulae() {
  if ! brew help trust >/dev/null 2>&1; then
    return 0
  fi

  # Brewfile の外部 tap entry だけを信頼する。
  brew trust --formula \
    smudge/smudge/nightlight \
    stripe/stripe-cli/stripe
  brew trust --cask \
    nozomiishii/tap/brooklyn \
    stablyai/orca/orca
}

if ! command -v brew >/dev/null 2>&1; then
  echo -e "🍺 Installing Homebrew for Apple Silicon"
  sudo softwareupdate --install-rosetta --agree-to-license
  NONINTERACTIVE=1 \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo -e "🍺 Homebrew already installed — updating Homebrew and installed packages"
  brew update --force --quiet
  brew upgrade --quiet || { fix_brew_link_conflicts && brew upgrade --quiet; }
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

trust_brew_bundle_formulae

max_attempts="${BREW_BUNDLE_MAX_ATTEMPTS:-5}"
attempt=1
backoff_base="${BREW_BUNDLE_BACKOFF_SEC:-20}"

# Brewfile を正にする（入れて、Brewfile にないものを削除。App Store は対象外）。
# install と cleanup は一体にする（分けると node 等の依存を巻き添え削除するため）。
while [ "$attempt" -le "$max_attempts" ]; do
  echo "brew bundle attempt ${attempt}/${max_attempts}"
  if HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}" brew bundle \
    --verbose \
    --cleanup \
    --force \
    --file="$SCRIPT_DIR/Brewfile"; then
    echo "brew bundle succeeded"
    break
  fi
  if [ "$attempt" -eq "$max_attempts" ]; then
    echo "brew bundle failed after ${max_attempts} attempts"
    exit 1
  fi

  fix_brew_link_conflicts

  sleep "$((backoff_base * attempt))"
  attempt="$((attempt + 1))"
done

# 古いバージョン・キャッシュを削除してディスクを空ける
brew cleanup --verbose
