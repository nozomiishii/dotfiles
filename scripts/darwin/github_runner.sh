#!/usr/bin/env bash
# GitHub Actions self-hosted runner のセットアップ (Apple Silicon Mac 専用)。
# runner バイナリの配置、設定ファイル雛形の作成、GitHub App private key の
# Keychain 登録、launchd (LaunchAgent) への登録を行う。
#
# 前提: make link 済み (plist と github-runner.sh のシンボリックリンクが必要)。
# GitHub App の作成手順や conf の記入方法は docs/github-runner.md を参照。
# 冪等なので、conf を記入したあと再実行して launchd 登録だけ進めることもできる。

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# actions/runner の osx-arm64 リリース。SHA-256 はリリースノート記載の値。
# https://github.com/actions/runner/releases
RUNNER_VERSION="2.336.0"
RUNNER_SHA256="8e8839c49b7060b6b2154f4931f815df330c27f167d53ef2239ee3dfce28b079"
KEYCHAIN_SERVICE="github-runner-app-key"
INSTANCES=(runner1 runner2)

echo "🏃 Setting up GitHub Actions self-hosted runners..."

if [ "$(uname -m)" != "arm64" ]; then
  echo "ERROR: this script downloads the osx-arm64 runner and supports Apple Silicon only" >&2
  exit 1
fi

# ----------------------------------------------------------------
# Runner binary
# ----------------------------------------------------------------
for instance in "${INSTANCES[@]}"; do
  runner_dir="$HOME/actions-runner/${instance}"

  if [ -x "${runner_dir}/config.sh" ]; then
    echo "- ${instance}: runner binary already in place"
    continue
  fi

  echo "- ${instance}: downloading actions-runner v${RUNNER_VERSION} (osx-arm64)"
  tmp_dir="$(mktemp -d)"
  tarball="${tmp_dir}/actions-runner.tar.gz"
  curl -fsSL -o "$tarball" \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"
  echo "${RUNNER_SHA256}  ${tarball}" | shasum -a 256 --check --status
  mkdir -p "$runner_dir"
  tar xzf "$tarball" -C "$runner_dir"
  rm -rf "$tmp_dir"
done

# ----------------------------------------------------------------
# Config template
# ----------------------------------------------------------------
# 対象 repo や GitHub App の固有値は public な dotfiles に置かず、ここで管理する
conf_dir="$HOME/.config/github-runner"
mkdir -p "$conf_dir"

for instance in "${INSTANCES[@]}"; do
  conf="${conf_dir}/${instance}.conf"

  if [ -f "$conf" ]; then
    echo "- ${instance}: config already exists ($conf)"
    continue
  fi

  echo "- ${instance}: creating config template ($conf)"
  cat > "$conf" << 'EOF'
# github-runner.sh が読む設定。値の控え方は docs/github-runner.md の Phase A を参照。
GITHUB_REPO=""          # 対象 repo (<owner>/<repo> 形式)
APP_CLIENT_ID=""        # GitHub App の Client ID
APP_INSTALLATION_ID=""  # App を対象 repo にインストールした際の installation ID
EOF
done

# ----------------------------------------------------------------
# GitHub App private key (Keychain)
# ----------------------------------------------------------------
# -T /usr/bin/security: launchd 配下の github-runner.sh が security コマンドで
# 無人読み出しできるよう ACL を付与する
if security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" > /dev/null 2>&1; then
  echo "- Keychain: private key already registered (service: ${KEYCHAIN_SERVICE})"
elif [ -t 0 ]; then
  echo "- Keychain: GitHub App private key (.pem) のパスを入力 (空 Enter でスキップ)"
  read -r -p "  pem path: " pem_path
  if [ -n "$pem_path" ]; then
    security add-generic-password \
      -s "$KEYCHAIN_SERVICE" \
      -a "$USER" \
      -w "$(cat "$pem_path")" \
      -T /usr/bin/security
    echo "- Keychain: registered. 登録済みの pem ファイルは削除を推奨"
  fi
else
  echo "- Keychain: private key not registered (non-interactive; re-run in a terminal)"
fi

# ----------------------------------------------------------------
# launchd
# ----------------------------------------------------------------
for instance in "${INSTANCES[@]}"; do
  conf="${conf_dir}/${instance}.conf"

  # conf が未記入のまま KeepAlive で起動すると失敗ループになるため、記入済みの時だけ登録する
  if ! (
    # shellcheck source=/dev/null
    source "$conf"
    [ -n "${GITHUB_REPO:-}" ] && [ -n "${APP_CLIENT_ID:-}" ] && [ -n "${APP_INSTALLATION_ID:-}" ]
  ); then
    echo "- ${instance}: ${conf} が未記入のため launchd 登録をスキップ (記入後に再実行)"
    continue
  fi

  plist="$HOME/Library/LaunchAgents/local.github-runner.${instance}.plist"
  echo "- ${instance}: registering LaunchAgent"
  launchctl bootout "gui/$UID" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
done

echo "🏃 Done. 各 repo の Settings > Actions > Runners で Idle 表示を確認してください"
