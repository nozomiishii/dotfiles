# shellcheck shell=bash
# Codex はコマンドを bash -lc で実行する。macOS の /etc/profile が呼ぶ path_helper が
# 継承した ~/.local/bin を /etc/paths.d 由来の Homebrew より後ろへ回すため、gh シムが
# 実体より先に解決されるようここで前置し直す。zsh 側は .zprofile が同じ役割を持つ。
export PATH="$HOME/.local/bin:$PATH"
