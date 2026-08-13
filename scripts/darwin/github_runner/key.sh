#!/usr/bin/env bash
# GitHub App private key の Keychain 登録。
# 初回セットアップのほか、鍵のローテーションやマシン移行のたびに単独で実行する。
# 鍵はバックアップせず、マシンごとに App の設定ページで再生成して登録し直す運用
# (再生成しても Client ID と installation ID は変わらない)。
#
# バイナリ配置は setup_arm64.sh、launchd への登録は launchd.sh が担う。

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
set -Ceuo pipefail

# github-runner.sh (make_jwt) が読み出すときの Keychain item 名
KEYCHAIN_SERVICE="github-runner-app-key"

echo "🔑 Registering GitHub App private key to Keychain..."

# -T /usr/bin/security: launchd 配下の github-runner.sh が security コマンドで
# 無人読み出しできるよう ACL を付与する
if security find-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" > /dev/null 2>&1; then
  echo "- Keychain: already registered (service: ${KEYCHAIN_SERVICE})"
  echo "  置き換える場合: security delete-generic-password -s ${KEYCHAIN_SERVICE} -a \"\$USER\" を実行してから再実行"
elif [ -t 0 ]; then
  echo "- GitHub App private key (.pem) のパスを入力 (空 Enter でスキップ)"
  read -r -p "  pem path: " pem_path
  if [ -n "$pem_path" ]; then
    security add-generic-password \
      -s "$KEYCHAIN_SERVICE" \
      -a "$USER" \
      -w "$(cat "$pem_path")" \
      -T /usr/bin/security
    echo "- Keychain: registered. 動作確認が済んだら pem ファイルを削除してください"
  fi
else
  echo "- Keychain: not registered (non-interactive; re-run in a terminal)"
fi
