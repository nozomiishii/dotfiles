#!/usr/bin/env bash
# GitHub Actions self-hosted runner の launchd (LaunchAgent) 登録。
# conf を記入したあとや plist を変更したあとに単独で実行する。
#
# 前提: make link 済み (plist と github-runner.sh のシンボリックリンクが必要)。
# バイナリ配置は setup.sh、鍵の登録は key.sh が担う。

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# インスタンス一覧は setup.sh と home/Library/LaunchAgents/ の plist にも対応がある
INSTANCES=(runner1 runner2)

echo "🚀 Registering runner LaunchAgents..."

conf_dir="$HOME/.config/github-runner"

for instance in "${INSTANCES[@]}"; do
  conf="${conf_dir}/${instance}.conf"

  if [ ! -f "$conf" ]; then
    echo "- ${instance}: ${conf} が無いため launchd 登録をスキップ (先に 'make github-runner' を実行)"
    continue
  fi

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

echo "🚀 Done. 各 repo の Settings > Actions > Runners で Idle 表示を確認してください"
