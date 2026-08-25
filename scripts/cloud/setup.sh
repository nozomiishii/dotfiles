#!/bin/bash
# Claude Code on the web / Codex Cloud の Setup script 欄に貼る:
#   curl -fsSL https://raw.githubusercontent.com/nozomiishii/dotfiles/main/scripts/cloud/setup.sh | bash
set -euo pipefail

curl -fsSL "https://nozomiishii.github.io/dotfiles/cloud-setup.tar.gz" | tar xz

# Claude Code
mkdir -p ~/.claude
cp home/AGENTS.md ~/.claude/CLAUDE.md
jq 'del(.statusLine, .sandbox)' home/.claude/settings.json >~/.claude/settings.json

# Codex
mkdir -p ~/.codex
cp home/AGENTS.md ~/.codex/AGENTS.md

# Agents (skills)
mkdir -p ~/.agents ~/.claude/skills
cp -R home/.agents/. ~/.agents/
cp -R home/.agents/skills/. ~/.claude/skills/

# gh シム (PR タイトルを repo の commitlint 設定で検証する)
real_gh="$(command -v gh || true)"
shim_dir="$HOME/.local/bin"
# 実体 gh と同じディレクトリに置くと本物を潰し、委譲先を失って gh が全滅する
if [ -n "$real_gh" ] && [ "$shim_dir/gh" != "$real_gh" ]; then
  mkdir -p "$shim_dir"
  cp home/.local/bin/gh "$shim_dir/gh"
  chmod +x "$shim_dir/gh"

  # cloud のシェルは PATH を継承しないので、実体 gh より先に来るよう rc に前置を足す
  path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
  for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ "$rc" = "$HOME/.bash_profile" ] && [ ! -f "$rc" ]; then
      continue
    fi
    grep -qsF "$path_line" "$rc" || printf '%s\n' "$path_line" >>"$rc"
  done
fi

# direnv (.envrc のある repo で `direnv exec . <コマンド>` を使うのに必要)
# 公式 install.sh は api.github.com を叩く。cloud の egress IP は共有のため未認証
# rate limit (60 req/h) を使い切ると 403 で落ちる。release asset を直接取る。
if ! command -v direnv >/dev/null 2>&1; then
  bin_path=/usr/local/bin
  [ -w "$bin_path" ] || {
    bin_path="$HOME/.local/bin"
    mkdir -p "$bin_path"
  }
  case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *)
    echo "direnv: unsupported machine $(uname -m)" >&2
    exit 1
    ;;
  esac
  curl -fsSL -o "$bin_path/direnv" \
    "https://github.com/direnv/direnv/releases/latest/download/direnv.linux-$arch"
  chmod +x "$bin_path/direnv"
fi

# direnv whitelist。cloud の checkout 配下だけを信頼する (作業中に clone した
# 外部 repo の .envrc まで実行しないための信頼ゲート)。
mkdir -p ~/.config/direnv
cat >~/.config/direnv/direnv.toml <<EOF
[whitelist]
prefix = ["$PWD"]
EOF

rm -rf home/
