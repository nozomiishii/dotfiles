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

# brew bundle は fetch を全件まとめて 1 回の `brew fetch` に渡し、1 件でも失敗
# すると install フェーズに一切進まない (Library/Homebrew/bundle/installer.rb の
# "Failed to fetch" → return false)。到達不能な配布元が 1 つあるだけで、ダウン
# ロード済みのものまで含めて全パッケージが巻き添えになる。
# そのため bundle が通らなかったときは、エントリを 1 件ずつ入れ直して
# 1 件の失敗が他に波及しないようにする。
install_entries_individually() {
  local brewfile="$1"
  local failed=()
  local name

  # tap を先に入れる。nozomiishii/tap/brooklyn は tap が無いと解決できない。
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    brew tap "$name" || failed+=("tap $name")
  done < <(brew bundle list --file="$brewfile" --tap)

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    brew install --formula "$name" || failed+=("brew $name")
  done < <(brew bundle list --file="$brewfile" --formula)

  # cask は macOS 専用。brew bundle 本体は Skipper で Linux の cask を除外するが、
  # Lister は Skipper を通さない (Library/Homebrew/bundle/lister.rb) ため
  # `brew bundle list --cask` は Linux でも Brewfile の cask を返してしまう。
  # そのまま流すと Linux で必ず失敗するので、ここで OS を見て飛ばす。
  if [[ "$OS_NAME" == "Darwin" ]]; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      brew install --cask "$name" || failed+=("cask $name")
    done < <(brew bundle list --file="$brewfile" --cask)
  fi

  # 通常経路の `brew bundle --cleanup` と同じ状態に揃える。cleanup は Brewfile に
  # 無いものだけを消すので、入れ損ねたエントリには触れない。
  brew bundle cleanup --force --file="$brewfile" || true

  # bash 3.2 では set -u 下の "${failed[@]}" が空配列で unbound variable になる。
  # 件数でガードしてから展開する。
  if [ "${#failed[@]}" -gt 0 ]; then
    echo "⚠️  個別インストールでも失敗したエントリ:" >&2
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
install_failed=0

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
    echo "brew bundle failed after ${max_attempts} attempts — falling back to individual installs"
    install_entries_individually "$SCRIPT_DIR/Brewfile" || install_failed=1
    break
  fi

  fix_brew_link_conflicts

  sleep "$((backoff_base * attempt))"
  attempt="$((attempt + 1))"
done

# 古いバージョン・キャッシュを削除してディスクを空ける
brew cleanup --verbose

# 入れられるものは入れ切った上で、残った失敗は呼び出し元に伝える。
# make homebrew 単体実行と lefthook の post-merge で失敗を検知できる状態を保つ。
# install.sh から呼ばれた場合は、この非ゼロを受け取っても後続ステップを続行する。
if [ "$install_failed" -ne 0 ]; then
  exit 1
fi
