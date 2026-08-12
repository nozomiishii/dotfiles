#!/usr/bin/env bash

# -C          : Prevent overwriting existing files when redirecting output.
#               - Helps to avoid accidentally overwriting files when using
#                 redirection operators like > or >> in the script.
# -e          : Exit the script if any command returns a non-zero status.
#               - Ensures the script stops on the first error encountered.
# -u          : Exit the script if an undefined variable is used.
#               - Prevents running commands with unintended variables.
# -o pipefail : Change pipeline exit status to the last non-zero exit code
#               in the pipeline, or zero if all commands succeed.
#               - Ensures proper error handling in pipelines.
# -x          : (Optional) Enable command tracing for easier debugging.
#               - Uncomment this option to debug the script.
set -Ceuo pipefail

# Ensure UTF-8 encoding for special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

DOTFILES_REPO="https://github.com/nozomiishii/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Code/nozomiishii/dotfiles}"
OS_NAME="$(uname -s)"

# この placeholder があると softwareupdate -l が CLT をアップデート対象として列挙する
CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

# ----------------------------------------------------------------
# utils
# ----------------------------------------------------------------
yellow='\033[1;33m'
reset='\033[0m'

# アプリのインストールなど一部のステップが落ちても、残りのステップは走らせて
# セットアップを最後まで進める。1 つの配布元が落ちただけで symlink や toolchain の
# セットアップまで巻き添えで止まるのを防ぐ。
# 失敗は握りつぶさず FAILED_STEPS に積み、最後にまとめて報告して非ゼロで終了する。
FAILED_STEPS=()

run_step() {
  local label="$1"
  shift

  if "$@"; then
    return 0
  fi

  echo -e "⚠️  ${label} failed — continuing with the remaining steps" >&2
  FAILED_STEPS+=("$label")
  return 0
}

# homebrew.sh が失敗して brew が無い状態でも、後続ステップに進めるようにする。
load_brew_shellenv() {
  local brew_bin="$1"

  if [ ! -x "$brew_bin" ]; then
    echo -e "⚠️  ${brew_bin} not found — skipping shellenv" >&2
    return 0
  fi

  eval "$("$brew_bin" shellenv)"
}

# request_admin_privileges is kept in this file (not extracted to a script)
# because it manages main-process state: it sets an EXIT trap and starts a
# background sudo keepalive. Running it in a subshell would not affect the
# current process, so it must remain here.
request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  echo -e "- 👨🏻‍🚀 Please enter your password to grant sudo access for this operation"
  sudo -v

  SUDOERS_FILE="/etc/sudoers.d/temp_dotfiles_installer"
  sudo sh -c "echo 'Defaults timestamp_timeout=120' > ${SUDOERS_FILE}"
  sudo chmod 0440 "${SUDOERS_FILE}"
  # bash の EXIT trap は 1 本のみ。placeholder の掃除もここに集約する
  # (ensure_xcode_clt で trap を新設すると sudoers の掃除を上書きして壊す)
  trap 'sudo rm -f "${SUDOERS_FILE}" "${CLT_PLACEHOLDER}"' EXIT

  sudo -v

  (
    while true; do
      sleep 10
      # subshell は set -e を継承する。一時的な失敗で keepalive が静かに死ぬと
      # 後半の sudo が tty で再プロンプトして無人実行が止まるため、失敗を握りつぶす
      sudo -n true || true
      kill -0 "$$" || exit
    done
  ) 2>/dev/null &
}

# ~/Documents 初回アクセスの TCC ダイアログを、パスワード入力直後のユーザーが
# まだ手元にいるタイミングに前倒しする。symlink.sh が ~/Documents/superwhisper を
# 張る数十分後に出ると、無人実行がそこで止まる。
request_documents_access() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  if ! ls "$HOME/Documents" > /dev/null 2>&1; then
    echo "- 👨🏻‍🚀 Terminal needs access to ~/Documents." >&2
    echo "  Allow it in System Settings > Privacy & Security > Files and Folders, then re-run." >&2
    exit 1
  fi
}
# ensure_xcode_clt はスクリプトに切り出さず、このファイルに置く。
# repo の clone には git が必要で、素の Mac では git を使うのに Command Line Tools が要る。
# つまり curl | bash 経路でこの処理が走る時点では、repo のスクリプトはまだ手元に存在しない。
#
# Homebrew install.sh と同じ softwareupdate ヘッドレス方式でインストールし、
# curl | bash 一発で最後まで走り切れるようにする。失敗時だけ GUI インストーラーに
# フォールバックして再実行を促す。
# @See https://developer.apple.com/documentation/xcode/installing-the-command-line-tools
# @See https://github.com/Homebrew/install/blob/master/install.sh
ensure_xcode_clt() {
  echo "- 👨🏻‍🚀 Checking Xcode CLI tools..."

  if xcode-select -p &>/dev/null; then
    echo "- 👨🏻‍🚀 Xcode CLI tools are already installed"
    return
  fi

  echo "- 👨🏻‍🚀 Xcode CLI tools not found. Installing them (this may take a while)..."
  # 前回の中断で root 所有の残骸が残っていても上書きできるよう sudo で作る
  sudo touch "${CLT_PLACEHOLDER}"

  # ラベル例: "Command Line Tools for Xcode-16.4"
  # ラベルが見つからないと grep が非ゼロ終了し pipefail でパイプ全体が失敗するため、
  # || true で空文字に落として下のフォールバック判定に委ねる
  local clt_label
  clt_label="$(softwareupdate -l 2> /dev/null \
    | grep -B 1 -E 'Command Line Tools' \
    | awk -F'*' '/^ *\*/ {print $2}' \
    | sed -e 's/^ *Label: //' -e 's/^ *//' \
    | sort -V \
    | tail -n 1 \
    || true)"

  if [ -n "${clt_label}" ]; then
    echo "- 👨🏻‍🚀 Installing: ${clt_label}"
    # 失敗しても set -e で即死させず、下の検証とフォールバックに進める
    sudo softwareupdate -i "${clt_label}" --verbose || true
  fi

  sudo rm -f "${CLT_PLACEHOLDER}"

  # インストール失敗時はディレクトリが無く、無条件に switch すると set -e で死ぬ
  if [ -d /Library/Developer/CommandLineTools ]; then
    sudo xcode-select --switch /Library/Developer/CommandLineTools
  fi

  if xcode-select -p &>/dev/null; then
    echo "- 👨🏻‍🚀 Xcode CLI tools are ready to go 🎉"
    return
  fi

  echo "⚠️ Automatic installation failed. Opening Apple's installer instead..." >&2
  if xcode-select --install; then
    echo "- 👨🏻‍🚀 The Xcode CLI tools installation was requested."
  else
    echo "⚠️ Could not open the Xcode CLI tools installer. It may already be open." >&2
  fi
  echo "Complete the installation, then re-run this dotfiles installer." >&2
  exit 1
}

clone_dotfiles_repo() {
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    return
  fi

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "👨🏻‍🚀 Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" pull --rebase
  else
    echo "👨🏻‍🚀 Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  SCRIPT_DIR="$DOTFILES_DIR"
}

# ----------------------------------------------------------------
# Install
# ----------------------------------------------------------------
echo -e "${yellow}"
printf '%s\n' \
  "👨🏻‍🚀 Nozomiishii Doting Dotfiles" \
  "   Get ready for your ultimate Mac setup!" \
  "" \
  "██████╗░░█████╗░████████╗███████╗██╗██╗░░░░░███████╗░██████╗" \
  "██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║██║░░░░░██╔════╝██╔════╝" \
  "██║░░██║██║░░██║░░░██║░░░█████╗░░██║██║░░░░░█████╗░░╚█████╗░" \
  "██║░░██║██║░░██║░░░██║░░░██╔══╝░░██║██║░░░░░██╔══╝░░░╚═══██╗" \
  "██████╔╝╚█████╔╝░░░██║░░░██║░░░░░██║███████╗███████╗██████╔╝" \
  "╚═════╝░░╚════╝░░░░╚═╝░░░╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═════╝░" \
  ""
echo -e "${reset}"

if [[ "$OS_NAME" == "Darwin" ]]; then
  # 人間の操作 (パスワード入力・TCC ダイアログ) を先頭に集約する。
  # ensure_xcode_clt は sudo を使い、CLT のダウンロードに数十分かかることがあるため、
  # sudoers + keepalive を先に確立してからヘッドレスで走らせる
  request_admin_privileges
  request_documents_access
  ensure_xcode_clt
  clone_dotfiles_repo
  run_step "nix.sh" bash "$SCRIPT_DIR/scripts/nix.sh"
  run_step "homebrew.sh" bash "$SCRIPT_DIR/scripts/homebrew.sh"
  load_brew_shellenv /opt/homebrew/bin/brew
  run_step "symlink.sh" bash "$SCRIPT_DIR/scripts/symlink.sh"
  run_step "darwin/macos.sh" bash "$SCRIPT_DIR/scripts/darwin/macos.sh"
  run_step "toolchains/node.sh" bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  run_step "toolchains/python.sh" bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  run_step "toolchains/ruby.sh" bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  run_step "toolchains/rust.sh" bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  run_step "toolchains/terraform.sh" bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
  run_step "toolchains/claude-code.sh" bash "$SCRIPT_DIR/scripts/toolchains/claude-code.sh"
  run_step "toolchains/pm.sh" bash "$SCRIPT_DIR/scripts/toolchains/pm.sh"
  run_step "default_apps.sh" bash "$SCRIPT_DIR/scripts/default_apps.sh"
  run_step "darwin/open_config_apps.sh" bash "$SCRIPT_DIR/scripts/darwin/open_config_apps.sh"
fi

if [[ "$OS_NAME" == "Linux" ]]; then
  clone_dotfiles_repo
  run_step "nix.sh" bash "$SCRIPT_DIR/scripts/nix.sh"
  run_step "zsh.sh" bash "$SCRIPT_DIR/scripts/zsh.sh"
  run_step "homebrew.sh" bash "$SCRIPT_DIR/scripts/homebrew.sh"
  load_brew_shellenv /home/linuxbrew/.linuxbrew/bin/brew
  run_step "symlink.sh" bash "$SCRIPT_DIR/scripts/symlink.sh"
  run_step "toolchains/node.sh" bash "$SCRIPT_DIR/scripts/toolchains/node.sh"
  run_step "toolchains/python.sh" bash "$SCRIPT_DIR/scripts/toolchains/python.sh"
  run_step "toolchains/ruby.sh" bash "$SCRIPT_DIR/scripts/toolchains/ruby.sh"
  run_step "toolchains/rust.sh" bash "$SCRIPT_DIR/scripts/toolchains/rust.sh"
  run_step "toolchains/terraform.sh" bash "$SCRIPT_DIR/scripts/toolchains/terraform.sh"
  run_step "toolchains/claude-code.sh" bash "$SCRIPT_DIR/scripts/toolchains/claude-code.sh"
  run_step "toolchains/pm.sh" bash "$SCRIPT_DIR/scripts/toolchains/pm.sh"
fi

# 失敗したステップがあっても最後までは実行している。ここで初めて非ゼロを返す。
# bash 3.2 では set -u 下の "${FAILED_STEPS[@]}" が空配列で unbound variable に
# なるため、件数でガードしてから展開する。
if [ "${#FAILED_STEPS[@]}" -gt 0 ]; then
  echo -e "${yellow}"
  printf '%s\n' \
    "" \
    "⚠️  セットアップは最後まで実行しましたが、失敗したステップがあります:" \
    ""
  printf '      - %s\n' "${FAILED_STEPS[@]}"
  printf '%s\n' \
    "" \
    "    ログを確認して、個別に再実行してください:" \
    "      bash $SCRIPT_DIR/scripts/<script>" \
    "" \
    "    Homebrew だけ入れ直す場合:" \
    "      make -C \"$SCRIPT_DIR\" homebrew" \
    "" \
    ""
  echo -e "${reset}"
  exit 1
fi

echo -e "${yellow}"
printf '%s\n' \
  "" \
  "" \
  "" \
  "░█████╗░░█████╗░███╗░░██╗░██████╗░██████╗░░█████╗░████████╗░██████╗██╗" \
  "██╔══██╗██╔══██╗████╗░██║██╔════╝░██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║" \
  "██║░░╚═╝██║░░██║██╔██╗██║██║░░██╗░██████╔╝███████║░░░██║░░░╚█████╗░██║" \
  "██║░░██╗██║░░██║██║╚████║██║░░╚██╗██╔══██╗██╔══██║░░░██║░░░░╚═══██╗╚═╝" \
  "╚█████╔╝╚█████╔╝██║░╚███║╚██████╔╝██║░░██║██║░░██║░░░██║░░░██████╔╝██╗" \
  "░╚════╝░░╚════╝░╚═╝░░╚══╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░╚═╝" \
  "" \
  "" \
  "🎉 All dotfiles installation is now complete 🎉" \
  "" \
  "" \
  "👨🏻‍🚀 Restart your mac to reflect the settings. Happy Coding🫰🏻" \
  "" \
  "    run:" \
  "      sudo reboot" \
  "" \
  "" \
  "📦 If Homebrew was interrupted:" \
  "" \
  "    run:" \
  "      make -C \"$SCRIPT_DIR\" homebrew" \
  "" \
  "" \
  "📦 After restarting, complete the remaining setup:" \
  "" \
  "    Follow the \"After installation\" section in:" \
  "      $SCRIPT_DIR/README.md" \
  "" \
  ""
echo -e "${reset}"
