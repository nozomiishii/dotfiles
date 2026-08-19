#!/usr/bin/env bash
# Raycast の手動 export を検知し、dotfiles の更新 PR を作る。
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

        if [ -n "$url" ]; then
                terminal-notifier -group local.raycast-backup -title "Raycast Backup" \
                        -message "$message" -sound "$sound" -open "$url"
        else
                terminal-notifier -group local.raycast-backup -title "Raycast Backup" \
                        -message "$message" -sound "$sound"
        fi
}

file_identity() {
	local candidate="$1" kind size
	[ -f "$candidate" ] && [ ! -L "$candidate" ] || return 1
	kind="$(stat -f '%HT' "$candidate")" || return 1
	[ "$kind" = "Regular File" ] || return 1
	size="$(stat -f '%z' "$candidate")" || return 1
	[ "$size" -gt 0 ] || return 1
	stat -f '%d:%i:%z:%m:%c' "$candidate"
}

wait_for_complete_export() {
	local candidate="$1" previous="" current="" stable=0 attempt=0

	# 書込み中の停止も拾えるよう、2秒間隔で3回連続の安定を確認する。
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

create_pr() (
	set -Ceuo pipefail
	export GIT_TERMINAL_PROMPT=0 GH_PROMPT_DISABLED=1

	# 関数全体がsubshellなので、trapから参照する変数はlocalにしない。
	candidate="$1"
	expected_identity="$2"
	branch_created=0
	worktree_added=0
	branch="chore/raycast-backup-$(date +%Y%m%d-%H%M%S)-$RANDOM"
	temporary_root="$(mktemp -d)"
	worktree="$temporary_root/worktree"
	trap '
		if [ "$worktree_added" -eq 1 ] &&
			! git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1; then
			printf "Raycast backup: worktree cleanup failed: %s\n" "$worktree" >&2
		else
			[ "$branch_created" -eq 0 ] ||
				git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1 || true
			rm -rf "$temporary_root"
		fi
	' EXIT

	git -C "$repo_root" fetch origin >&2
	git -C "$repo_root" worktree add -b "$branch" "$worktree" origin/main >&2
	branch_created=1
	worktree_added=1

	destination="$worktree/$backup_rel/$fixed_name"
	rm -f "$destination"
	cp -pP "$candidate" "$destination"
	[ -f "$destination" ] && [ ! -L "$destination" ]
	[ "$(file_identity "$candidate")" = "$expected_identity" ]
	cmp -s "$candidate" "$destination"

	git -C "$worktree" add "$backup_rel/$fixed_name"
	if git -C "$worktree" diff --cached --quiet; then
		if [ "$(file_identity "$candidate" 2>/dev/null || true)" = "$expected_identity" ] && \
			cmp -s "$candidate" "$destination"; then
			rm -f "$candidate"
		fi
		printf 'NO_CHANGES\n'
		exit 0
        fi

        git -C "$worktree" commit -m "chore: update Raycast config" >&2
        git -C "$worktree" push -u origin "$branch" >&2
	url="$(cd "$worktree" && gh pr create --base main \
		--title "chore: update Raycast config" --body "Raycast 設定のバックアップを更新します。")"
	printf '%s\n' "$url" | grep -Eq '^https://github\.com/[^/]+/[^/]+/pull/[0-9]+$'

	if [ "$(file_identity "$candidate" 2>/dev/null || true)" = "$expected_identity" ] && \
		cmp -s "$candidate" "$destination"; then
		rm -f "$candidate"
	fi
	printf 'PR\t%s\n' "$url"
)

handle_export() {
	local candidate="$1" name="${1##*/}" identity identity_tail file_key result status url

	[ "${candidate%/*}" = "${export_dir%/}" ] || return 0
	[ "$name" != "$fixed_name" ] || return 0
	case "$name" in *.rayconfig) ;; *) return 0 ;; esac
	identity="$(file_identity "$candidate")" || return 0
	identity_tail="${identity#*:}"
	file_key="${identity%%:*}:${identity_tail%%:*}"
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

	result="$(create_pr "$candidate" "$identity")"
        status=$?
        if [ "$status" -ne 0 ]; then
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
