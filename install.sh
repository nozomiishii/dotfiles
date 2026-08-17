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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: This dotfiles installer supports macOS only." >&2
  exit 1
fi

# Ensure UTF-8 encoding for special characters
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

DOTFILES_REPO="https://github.com/nozomiishii/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/Code/nozomiishii/dotfiles}"

# この placeholder があると softwareupdate -l が CLT をアップデート対象として列挙する
CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

# ----------------------------------------------------------------
# utils
# ----------------------------------------------------------------
yellow='\033[1;33m'
reset='\033[0m'

# request_admin_privileges is kept in this file (not extracted to a script)
# because it manages main-process state: it sets an EXIT trap. Running it in
# a subshell would not affect the current process, so it must remain here.
#
# timestamp_timeout + keepalive (sudo -n true) の延命方式は使わない。
# brew は起動するたびに `sudo --reset-timestamp` で sudo の認証キャッシュを
# 破棄するため (Library/Homebrew/brew.sh)、homebrew.sh 以降の sudo が tty で
# 再プロンプトしてしまう。そこでインストール中だけ NOPASSWD を付与し、
# 終了時に EXIT trap で取り除く。
# @See https://github.com/Homebrew/brew/commit/2adf25dcaf
request_admin_privileges() {
  if [ "${CI:-false}" = "true" ]; then
    return
  fi

  echo -e "- 👨🏻‍🚀 Please enter your password to grant sudo access for this operation"
  sudo -v

  SUDOERS_FILE="/etc/sudoers.d/temp_dotfiles_installer"
  # bash の EXIT trap は 1 本のみ。placeholder の掃除もここに集約する
  # (ensure_xcode_clt で trap を新設すると sudoers の掃除を上書きして壊す)
  trap 'sudo rm -f "${SUDOERS_FILE}" "${SUDOERS_FILE}.tmp" "${CLT_PLACEHOLDER}"' EXIT

  # 壊れた sudoers.d ファイルは sudo 自体を使用不能にするため、反映前に検証する。
  # includedir は '.' を含むファイル名を無視するので、.tmp のまま検証してから mv する
  sudo sh -c "echo '$(id -un) ALL=(ALL) NOPASSWD: ALL' > ${SUDOERS_FILE}.tmp"
  sudo chmod 0440 "${SUDOERS_FILE}.tmp"
  if ! sudo visudo -c -f "${SUDOERS_FILE}.tmp" > /dev/null; then
    sudo rm -f "${SUDOERS_FILE}.tmp"
    echo "⚠️ Failed to validate ${SUDOERS_FILE}.tmp — aborting so sudo stays usable" >&2
    exit 1
  fi
  sudo mv "${SUDOERS_FILE}.tmp" "${SUDOERS_FILE}"
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

# 人間の操作 (パスワード入力・TCC ダイアログ) を先頭に集約する。
# ensure_xcode_clt は sudo を使い、CLT のダウンロードに数十分かかることがあるため、
# NOPASSWD sudoers を先に確立してからヘッドレスで走らせる
request_admin_privileges
request_documents_access
ensure_xcode_clt
clone_dotfiles_repo
bash "$SCRIPT_DIR/scripts/nix.sh"
bash "$SCRIPT_DIR/scripts/homebrew.sh"
eval "$(/opt/homebrew/bin/brew shellenv)"
bash "$SCRIPT_DIR/scripts/symlink.sh"
bash "$SCRIPT_DIR/scripts/darwin/macos.sh"
bash "$SCRIPT_DIR/scripts/toolchains/mise.sh"
bash "$SCRIPT_DIR/scripts/toolchains/claude-code.sh"
bash "$SCRIPT_DIR/scripts/toolchains/pm.sh"
bash "$SCRIPT_DIR/scripts/default_apps.sh"
bash "$SCRIPT_DIR/scripts/darwin/open_config_apps.sh"

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
