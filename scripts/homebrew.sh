#!/usr/bin/env bash

# -C          : Prevent overwriting files with output redirection
# -e          : Exit the script if any command returns a non-zero status
# -u          : Exit the script if an undefined variable is used
# -o pipefail : Change pipeline exit status to the last non-zero exit
#               code in the pipeline, or zero if all commands succeed
# -x          : (Optional) Enable command tracing for easier debugging
set -Ceuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS_NAME="$(uname -s)"

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

# cask の配布元は Homebrew の CDN ではなくベンダー各社のサーバーで、formula より
# 到達に失敗しやすい (例: appcleaner の配布元が DNS フィルタに誤分類されて
# 0.0.0.0 に解決された #1538)。brew bundle は fetch を全件まとめて実行し、1 件
# でも失敗すると install フェーズに一切進まない (Library/Homebrew/bundle/installer.rb
# の "Failed to fetch" → return false) ため、cask を一括 fetch に混ぜると 1 つの
# 配布元の問題で全パッケージが巻き添えになる。そこで cask は bundle に任せず
# 最初から 1 件ずつ入れて、失敗をその cask だけに閉じ込める。
# 既に入っている cask は飛ばすので再実行は差分だけになる。更新は冒頭の
# brew upgrade が formula と cask の両方を対象にしている。
# cask は macOS 専用。Lister は Skipper を通さない (Library/Homebrew/bundle/lister.rb)
# ため `brew bundle list --cask` は Linux でも Brewfile の cask を返してしまうので、
# 呼び出し元で OS を見てから呼ぶ。
install_casks_individually() {
  local brewfile="$1"
  local failed=()
  local installed name

  installed="$(brew list --cask 2>/dev/null || true)"

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    # tap 付きで宣言した cask も bundle list は短い名前で返すが、念のため揃える
    if grep -Fxq "${name##*/}" <<<"$installed"; then
      continue
    fi
    brew install --cask "$name" || failed+=("cask $name")
  done < <(brew bundle list --file="$brewfile" --cask)

  # bash 3.2 では set -u 下の "${failed[@]}" が空配列で unbound variable になる。
  # 件数でガードしてから展開する。
  if [ "${#failed[@]}" -gt 0 ]; then
    echo "⚠️  インストールに失敗した cask:" >&2
    printf '  - %s\n' "${failed[@]}" >&2
    return 1
  fi
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
    nozomiishii/tap/brooklyn
}

if [[ "$OS_NAME" == "Darwin" ]]; then
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
elif [[ "${OS_NAME}" == "Linux" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo -e "🍺 Installing Homebrew for ${OS_NAME}"
    NONINTERACTIVE=1 \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo -e "🍺 Homebrew already installed — updating Homebrew and installed packages"
    brew update --force --quiet
    brew upgrade --quiet || { fix_brew_link_conflicts && brew upgrade --quiet; }
  fi
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

trust_brew_bundle_formulae

max_attempts="${BREW_BUNDLE_MAX_ATTEMPTS:-5}"
attempt=1
backoff_base="${BREW_BUNDLE_BACKOFF_SEC:-20}"

# cask を bundle の一括 fetch から外す (インストールは後段で 1 件ずつ)。
# HOMEBREW_BUNDLE_CASK_SKIP は install にだけ効き、cleanup は Brewfile 全体から
# 残すものを決める (Library/Homebrew/bundle/subcommand/cleanup.rb) ため、
# skip した cask が cleanup に消されることはない。
cask_skip=""
if [[ "$OS_NAME" == "Darwin" ]]; then
  cask_skip="$(brew bundle list --file="$SCRIPT_DIR/Brewfile" --cask | tr '\n' ' ')"
fi

# Brewfile を正にする（入れて、Brewfile にないものを削除。App Store は対象外）。
# install と cleanup は一体にする（分けると node 等の依存を巻き添え削除するため）。
while [ "$attempt" -le "$max_attempts" ]; do
  echo "brew bundle attempt ${attempt}/${max_attempts}"
  if HOMEBREW_CURL_RETRIES="${HOMEBREW_CURL_RETRIES:-5}" \
    HOMEBREW_BUNDLE_CASK_SKIP="$cask_skip" \
    brew bundle \
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

# cask はここで 1 件ずつ入れる。1 件の失敗で他の cask を止めない。
install_failed=0
if [[ "$OS_NAME" == "Darwin" ]]; then
  install_casks_individually "$SCRIPT_DIR/Brewfile" || install_failed=1
fi

# 古いバージョン・キャッシュを削除してディスクを空ける
brew cleanup --verbose

# 入れられる cask は入れ切った上で、残った失敗は呼び出し元に伝える。
# make homebrew 単体実行と lefthook の post-merge で失敗を検知できる状態を保つ。
if [ "$install_failed" -ne 0 ]; then
  exit 1
fi
