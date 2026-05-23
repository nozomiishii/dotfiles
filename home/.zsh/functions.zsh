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
  local rows
  rows=$(csr-resolve.ts "$1") || return 1 # 各行: <uuid>\t<repo>\t<wt>\t<display>
  local -a lines
  lines=("${(@f)rows}")

  local line
  if (( ${#lines} > 1 )); then
    # 複数候補 → 各セッションの「最後の会話」を preview しながら fzf で選ぶ。
    if (( ! $+commands[fzf] )); then
      echo "csr: 複数候補があります（fzf 未導入のため一覧表示）:" >&2
      cut -f4 <<<"$rows" >&2
      return 1
    fi
    line=$(fzf --delimiter=$'\t' --with-nth=4 \
               --preview='csr-resolve.ts --preview {1}' \
               --preview-window='right:60%:wrap' <<<"$rows") || return 1
  else
    line=$lines[1]
  fi

  # zsh の `path` は $PATH に tie された配列なので変数名に使わない（git/claude が見つからなくなる）。
  local uuid repo wt
  IFS=$'\t' read -r uuid repo wt _ <<<"$line"

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
