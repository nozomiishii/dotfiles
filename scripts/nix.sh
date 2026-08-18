#!/usr/bin/env bash

# エラー・未定義変数・パイプラインの失敗で終了し、リダイレクトによる上書きを防ぐ
set -Ceuo pipefail

echo "👨🏻‍🚀 Install Nix"

# Determinate installer は既存の /nix があると --no-confirm でも進めず止まるため、
# 部分実行後の再実行では receipt を見てスキップする
if [ -e /nix/receipt.json ]; then
  echo "👨🏻‍🚀 Nix is already installed. Skipping"
  exit 0
fi

curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
