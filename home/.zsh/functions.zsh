# Create a directory and move it there
mkcd() {
  mkdir -p "$@" && cd "$_"
}

# Copy current directory as `cd <path>` to clipboard
jf() {
  local payload="cd $(printf '%q' "$PWD")"
  printf '%s' "$payload" | pbcopy
  printf '\033[32m✓\033[0m Copied to clipboard\n  \033[2m%s\033[0m\n' "$payload"
}

# csr (Claude Session Recover): 消えた worktree のローカルセッションを
# クラウドセッション URL または branch 名から復元して resume する。
# git hooks で worktree が自動削除された後の最終手段。設計: nozomiishii/dotfiles#1006
csr() {
  local res
  res=$(csr-resolve.ts "$1") || return 1 # "<repo>\t<worktree_path>\t<uuid>"
  # zsh の `path` は $PATH に tie された配列なので変数名に使わない（git/claude が見つからなくなる）。
  local repo wt uuid
  IFS=$'\t' read -r repo wt uuid <<<"$res"
  # worktree が無ければ detached HEAD で再構築する（元 branch は復元不可なので repo の主ブランチを使う）。
  if [[ ! -d $wt ]]; then
    if [[ $repo == "$wt" ]]; then
      # cwd が worktree 配下でない（repo==wt）→ 再構築する worktree が無く、ディレクトリも消えている。
      echo "csr: 非 worktree セッションのディレクトリが見つかりません: $wt" >&2
      return 1
    fi
    local mb
    mb=$(cd "$repo" && git_main_branch) || return 1
    git -C "$repo" worktree add --detach "$wt" "$mb" || return 1
  fi
  cd "$wt" && claude --resume "$uuid"
}
