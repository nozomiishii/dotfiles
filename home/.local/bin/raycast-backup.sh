#!/usr/bin/env bash
# Raycast の手動 export を検知し、dotfiles の更新 PR を作る。
# 常駐 watcher のため errexit は付けず、1 回の失敗で止めない (PR 作成側は set -Ceu)。
set -uo pipefail

export_dir="${RAYCAST_EXPORT_DIR:-$HOME/.config/raycast/backup}"
backup_rel="home/.config/raycast/backup"
fixed_name="Raycast.rayconfig"
seen_files=$'\n'

# stow のリンクを辿り、repo の配置場所に依存せず実体を特定する。
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [ "${src#/}" = "$src" ] && src="$dir/$src"
done
repo_root="$(cd -P "$(dirname "$src")/../../.." && pwd)"

notify() {
  local status="$1" message="$2" url="${3:-}" sound="Basso"
  [ "$status" = success ] && sound="Glass"

  local args=(-group local.raycast-backup -title "Raycast Backup" -message "$message" -sound "$sound")
  [ -n "$url" ] && args+=(-open "$url")
  terminal-notifier "${args[@]}"
}

# 空でない通常ファイルのときだけ、識別子 dev:inode:size:mtime:ctime を出力する。
file_identity() {
  local candidate="$1" size
  [ -f "$candidate" ] && [ ! -L "$candidate" ] || return 1
  size="$(stat -f '%z' "$candidate")" || return 1
  [ "$size" -gt 0 ] || return 1
  stat -f '%d:%i:%z:%m:%c' "$candidate"
}

# 書き込み途中の export を掴まないよう、最大 30 秒 (2 秒間隔)、
# 識別子が 3 回連続で安定するまで待つ。
wait_for_complete_export() {
  local candidate="$1" previous="" current="" stable=0 attempt=0

  while [ "$attempt" -lt 15 ]; do
    current="$(file_identity "$candidate")" || return 1
    if [ "$current" = "$previous" ] && ! /usr/sbin/lsof "$candidate" >/dev/null 2>&1; then
      stable=$((stable + 1))
    else
      stable=0
    fi
    [ "$stable" -ge 3 ] && printf '%s\n' "$current" && return 0
    previous="$current"
    attempt=$((attempt + 1))
    sleep 2
  done
  return 1
}

# export 元が退避時と同一のままなら、取り込み済みとして削除する。
remove_consumed_export() {
  local candidate="$1" expected_identity="$2" destination="$3"
  if [ "$(file_identity "$candidate" 2>/dev/null || true)" = "$expected_identity" ] &&
    cmp -s "$candidate" "$destination"; then
    rm -f "$candidate"
  fi
}

# create_pr の EXIT trap。作業用の worktree・branch・一時ディレクトリを片付ける。
cleanup_pr_worktree() {
  local worktree_ready="$1" worktree="$2" branch="$3" temporary_root="$4"
  if [ "$worktree_ready" -eq 1 ]; then
    if ! git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1; then
      # 失敗時は調査できるよう worktree と branch を残す。
      printf 'Raycast backup: worktree cleanup failed: %s\n' "$worktree" >&2
      return 0
    fi
    git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1 || true
  fi
  rm -rf "$temporary_root"
}

create_pr() (
  set -Ceuo pipefail
  export GIT_TERMINAL_PROMPT=0 GH_PROMPT_DISABLED=1

  candidate="$1"
  expected_identity="$2"
  branch="chore/raycast-backup-$(date +%Y%m%d-%H%M%S)-$RANDOM"
  temporary_root="$(mktemp -d)"
  worktree="$temporary_root/worktree"
  worktree_ready=0
  # 変数は trap 発火時に展開させる (worktree_ready は後で変わる)。
  trap 'cleanup_pr_worktree "$worktree_ready" "$worktree" "$branch" "$temporary_root"' EXIT

  git -C "$repo_root" fetch origin >&2
  git -C "$repo_root" worktree add -b "$branch" "$worktree" origin/main >&2
  worktree_ready=1

  destination="$worktree/$backup_rel/$fixed_name"
  rm -f "$destination"
  cp -pP "$candidate" "$destination"

  # コピー中の再 export や symlink 差し替えを検出する (失敗すると set -e で中断)。
  [ -f "$destination" ] && [ ! -L "$destination" ]
  [ "$(file_identity "$candidate")" = "$expected_identity" ]
  cmp -s "$candidate" "$destination"

  git -C "$worktree" add "$backup_rel/$fixed_name"
  if git -C "$worktree" diff --cached --quiet; then
    remove_consumed_export "$candidate" "$expected_identity" "$destination"
    printf 'NO_CHANGES\n'
    exit 0
  fi

  git -C "$worktree" commit -m "chore: update Raycast config" >&2
  git -C "$worktree" push -u origin "$branch" >&2

  url="$(cd "$worktree" && gh pr create --base main \
    --title "chore: update Raycast config" --body "Raycast 設定のバックアップを更新します。")"
  # notify -open に渡すため、gh の出力が PR の URL であることを確認する。
  printf '%s\n' "$url" | grep -Eq '^https://github\.com/[^/]+/[^/]+/pull/[0-9]+$'

  remove_consumed_export "$candidate" "$expected_identity" "$destination"
  printf 'PR\t%s\n' "$url"
)

handle_export() {
  local candidate="$1" name="${1##*/}" identity dev inode file_key result url

  # 対象は export 先ディレクトリ直下の *.rayconfig のみ。
  # 固定名は stow でリンクされたバックアップ実体なので、再処理しない。
  [ "${candidate%/*}" = "${export_dir%/}" ] || return 0
  case "$name" in *.rayconfig) ;; *) return 0 ;; esac
  [ "$name" != "$fixed_name" ] || return 0
  identity="$(file_identity "$candidate")" || return 0

  # 同一ファイルへの複数イベント (Created + Renamed など) は dev:inode で間引く。
  IFS=: read -r dev inode _ <<<"$identity"
  file_key="$dev:$inode"
  case "$seen_files" in *$'\n'"$file_key"$'\n'*) return 0 ;; esac
  seen_files="${seen_files}${file_key}"$'\n'

  if ! identity="$(wait_for_complete_export "$candidate")"; then
    notify failure "exportの書き込み完了を確認できませんでした" || true
    return 0
  fi

  if ! gh auth status -h github.com >/dev/null 2>&1; then
    notify failure "GitHubの認証を確認してください" || true
    return 0
  fi

  if ! result="$(create_pr "$candidate" "$identity")"; then
    notify failure "RaycastバックアップのPRを作成できませんでした" || true
    return 0
  fi

  case "$result" in
  PR$'\t'*)
    url="${result#*$'\t'}"
    notify success "PRを作成しました" "$url" || true
    ;;
  NO_CHANGES) notify success "バックアップに変更はありませんでした" || true ;;
  esac
}

# terminal-notifier 自体が欠けている場合に備え、依存チェックの通知は osascript で出す。
for command_name in fswatch terminal-notifier gh git; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    /usr/bin/osascript -e "display notification \"$command_name が見つかりません\" with title \"Raycast Backup\"" || true
    exit 0
  fi
done

mkdir -p "$export_dir"
fswatch -r -0 --event Created --event MovedTo --event Renamed "$export_dir" |
  while IFS= read -r -d '' event_path; do
    handle_export "$event_path"
  done
