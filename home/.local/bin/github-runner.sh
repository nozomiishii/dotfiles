#!/usr/bin/env bash
# GitHub Actions self-hosted runner (ephemeral) の常駐ラッパー。
# launchd (local.github-runner.<instance>.plist) から起動され、
# 「registration token 取得 → 登録 → 1 ジョブ実行 → GitHub 側が自動登録解除」を無限ループで繰り返す。
# プロセスが死んだら launchd の KeepAlive が再起動する。
#
# 認証は GitHub App。Keychain の private key で JWT を作り、
# installation access token → runner registration token の順に交換する (どちらも 1 時間で失効)。
# @See https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app
# @See https://docs.github.com/en/rest/actions/self-hosted-runners
#
# 使い方: github-runner.sh <instance>
#   対象 repo や GitHub App の固有値は ~/.config/github-runner/<instance>.conf から読む。
#   セットアップ手順は docs/github-runner.md を参照。

set -uo pipefail

KEYCHAIN_SERVICE="github-runner-app-key"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

INSTANCE="${1:?usage: github-runner.sh <instance>}"
CONF="$HOME/.config/github-runner/${INSTANCE}.conf"
RUNNER_DIR="$HOME/actions-runner/${INSTANCE}"

if [ ! -f "$CONF" ]; then
  log "config not found: $CONF (run 'make github-runner' first)"
  exit 78 # EX_CONFIG
fi
# shellcheck source=/dev/null
source "$CONF"

for var in GITHUB_REPO APP_CLIENT_ID APP_INSTALLATION_ID; do
  if [ -z "${!var:-}" ]; then
    log "$var is empty in $CONF"
    exit 78 # EX_CONFIG
  fi
done

if [ ! -x "$RUNNER_DIR/config.sh" ]; then
  log "runner binary not found in $RUNNER_DIR (run 'make github-runner' first)"
  exit 78 # EX_CONFIG
fi

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

# GitHub App の JWT を生成する (公式ドキュメントの bash 例に準拠)
make_jwt() {
  local pem now header payload header_payload signature
  pem="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w)" || return 1
  now="$(date +%s)"
  header="$(printf '{"typ":"JWT","alg":"RS256"}' | b64enc)"
  payload="$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$((now - 60))" "$((now + 600))" "$APP_CLIENT_ID" | b64enc)"
  header_payload="${header}.${payload}"
  signature="$(printf '%s' "$header_payload" | openssl dgst -sha256 -sign <(printf '%s\n' "$pem") | b64enc)" || return 1
  printf '%s.%s' "$header_payload" "$signature"
}

github_api_token() {
  local auth_token="$1" url="$2" token
  token="$(
    curl -sS -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${auth_token}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$url" | jq -r '.token // empty'
  )" || return 1
  [ -n "$token" ] || return 1
  printf '%s' "$token"
}

get_registration_token() {
  local jwt installation_token
  jwt="$(make_jwt)" || {
    log "failed to build JWT (Keychain item '${KEYCHAIN_SERVICE}' missing?)"
    return 1
  }
  installation_token="$(github_api_token "$jwt" "https://api.github.com/app/installations/${APP_INSTALLATION_ID}/access_tokens")" || {
    log "failed to get installation access token"
    return 1
  }
  github_api_token "$installation_token" "https://api.github.com/repos/${GITHUB_REPO}/actions/runners/registration-token" || {
    log "failed to get runner registration token"
    return 1
  }
}

log "starting ephemeral runner loop: instance=${INSTANCE} repo=${GITHUB_REPO}"
cd "$RUNNER_DIR" || exit 1

while true; do
  registration_token="$(get_registration_token)" || {
    sleep 60
    continue
  }

  # 異常終了で残った前回の登録情報と作業ディレクトリを掃除してから登録する
  # (残っていると config.sh が "already configured" で失敗する)
  rm -rf .runner .credentials .credentials_rsaparams _work

  ./config.sh --unattended --ephemeral --replace \
    --url "https://github.com/${GITHUB_REPO}" \
    --token "$registration_token" \
    --name "$(hostname -s)-${INSTANCE}" || {
    log "config.sh failed"
    sleep 60
    continue
  }

  # ephemeral なので 1 ジョブ処理すると GitHub 側が登録解除し、run.sh が終了する
  ./run.sh || log "run.sh exited with $?"
done
