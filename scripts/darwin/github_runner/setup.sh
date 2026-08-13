#!/usr/bin/env bash
# GitHub Actions self-hosted runner の初回セットアップ (Apple Silicon Mac 専用)。
# runner バイナリの配置と、設定ファイル雛形の作成を行う。どちらも初回だけの関心で、
# 以後バイナリは run.sh の自動更新に任せる。
#
# 鍵の登録は key.sh、launchd への登録は launchd.sh が担う。
# 3 本まとめて実行するときは `make github-runner`。

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# インスタンス一覧は launchd.sh と home/Library/LaunchAgents/ の plist にも対応がある
INSTANCES=(runner1 runner2)

# 配置するバイナリは、公式の手動セットアップ手順と同じく、その時点の最新リリースを使う。
# 配置後は runner が自動更新するため、版を固定して追従し続ける意味が薄い。
# SHA-256 はリリースノート記載の値で、転送破損の検知用。
# https://github.com/actions/runner/releases
resolve_latest_release() {
  # 取得済みなら再利用 (2 インスタンス目で API を叩き直さない)
  [ -n "${RUNNER_VERSION:-}" ] && return 0
  local release_json
  release_json="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest)"
  RUNNER_VERSION="$(printf '%s' "$release_json" | jq -r '.tag_name // "" | ltrimstr("v")')"
  RUNNER_SHA256="$(printf '%s' "$release_json" | jq -r '.body // ""' | grep -oE 'BEGIN SHA osx-arm64 -->[a-f0-9]{64}' | grep -oE '[a-f0-9]{64}')"
  if [ -z "$RUNNER_VERSION" ] || [ -z "$RUNNER_SHA256" ]; then
    echo "ERROR: failed to resolve the latest actions/runner release" >&2
    return 1
  fi
}

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

  resolve_latest_release
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

echo "🏃 Setup done. conf を記入したら 'make github-runner-launchd' で launchd に登録してください"
