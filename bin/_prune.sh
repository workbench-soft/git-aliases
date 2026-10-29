#!/usr/bin/env bash
# Branch and worktree deletion for git db and git dbm. Needs _shared.sh first.

# Local branches whose upstream was deleted, one per line.
gone_branches() {
	git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ |
		awk '/\[gone\]/ {print $1}'
}

# Keep paths separate from picker labels, including paths with tabs or newlines.
load_deletion_worktrees() {
	local listing field index=-1
	listing=$(mktemp) || return
	if ! git worktree list --porcelain -z >"$listing"; then
		rm -f -- "$listing"
		return 1
	fi
	delete_paths=() delete_branches=() delete_heads=() delete_locked=()
	while IFS= read -r -d '' field; do
		case $field in
			'worktree '*)
				index=$((index + 1))
				delete_paths[index]=${field#worktree }
				delete_branches[index]=''
				delete_heads[index]=''
				delete_locked[index]=0
				;;
			'branch refs/heads/'*) delete_branches[index]=${field#branch refs/heads/} ;;
			'HEAD '*) delete_heads[index]=${field#HEAD } ;;
			locked*) delete_locked[index]=1 ;;
		esac
	done <"$listing"
	rm -f -- "$listing"
}

deletable_worktree() {
	local index=$1 here=$2 other path=${delete_paths[$1]}
	[ "$index" != 0 ] || return 1
	[ "$path" != "$here" ] || return 1
	[ "${delete_locked[index]}" = 0 ] || return 1
	for other in "${!delete_paths[@]}"; do
		[ "$other" != "$index" ] || continue
		case ${delete_paths[other]} in
			"$path"/*) return 1 ;;
		esac
	done
}

deletion_candidates() {
	local mode=$1 here current branches gone='' branch index held path
	here=$(git rev-parse --show-toplevel) || return
	current=$(git branch --show-current) || return
	branches=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/) || return
	if [ "$mode" = gone ]; then
		gone=$(gone_branches) || return
	fi
	while IFS= read -r branch; do
		[ -n "$branch" ] || continue
		[ "$branch" != "$current" ] || continue
		if [ "$mode" = gone ]; then
			case $'\n'"$gone"$'\n' in
				*$'\n'"$branch"$'\n'*) ;;
				*) continue ;;
			esac
		fi
		held=0
		for index in "${!delete_paths[@]}"; do
			[ "${delete_branches[index]}" = "$branch" ] || continue
			held=1
			deletable_worktree "$index" "$here" || continue
			path=${delete_paths[index]//$'\t'/ }
			path=${path//$'\n'/ }
			printf '%s\t%s\t[worktree] %s\n' "$branch" "$index" "$path"
		done
		if [ "$held" = 0 ]; then
			printf '%s\tbranch\t[branch]\n' "$branch"
		fi
	done <<<"$branches"
	if [ "$mode" = all ]; then
		for index in "${!delete_paths[@]}"; do
			[ -z "${delete_branches[index]}" ] || continue
			deletable_worktree "$index" "$here" || continue
			path=${delete_paths[index]//$'\t'/ }
			path=${path//$'\n'/ }
			printf '%s\t%s\t[worktree detached] %s\n' "${delete_heads[index]}" "$index" "$path"
		done
	fi
}

worktree_registered() {
	local field
	while IFS= read -r -d '' field; do
		[ "$field" != "worktree $1" ] || return 0
	done < <(git worktree list --porcelain -z)
	return 1
}

# A dev server running in the folder can write files while git deletes it.
# git then drops the registration and leaves the folder behind.
delete_leftover_folder() {
	local path=$1 attempt pids
	for attempt in 1 2 3; do
		[ -e "$path" ] || return 0
		[ "$attempt" = 1 ] || sleep 1
		run rm -rf -- "$path" && return 0
	done
	pids=''
	if command -v lsof >/dev/null 2>&1; then
		pids=$(lsof -t +d "$path" 2>/dev/null | sort -u | tr '\n' ' ') || true
	fi
	warn "could not delete '$path'${pids:+, processes still using it: $pids}"
}

# Removes a worktree only when git finds no changes in it. Fails if the
# worktree is still registered, which means it needs --force.
remove_clean_worktree() {
	local path=$1
	run git worktree remove -- "$path" && return 0
	# git checks for changes before it deletes. A dropped registration means none.
	worktree_registered "$path" && return 1
	delete_leftover_folder "$path"
}

force_remove_worktree() {
	local path=$1
	run git worktree remove --force -- "$path" && return 0
	delete_leftover_folder "$path"
	worktree_registered "$path" || return 0
	run git worktree remove --force -- "$path"
}

# Deletes the branch of a removed worktree, unless another worktree still uses it.
delete_worktree_branch() {
	local branch=$1 index=$2 remaining
	[ -n "${delete_branches[index]}" ] || return 0
	remaining=$(git for-each-ref --format='%(worktreepath)' "refs/heads/$branch")
	if [ -n "$remaining" ]; then
		note "Keeping branch '$branch': still used by worktree '$remaining'"
		return 0
	fi
	run git branch -D -- "$branch" || {
		warn "branch retained: $branch"
		return 1
	}
}

# Deletes what needs no question first. Worktrees with changes wait for the
# questions at the end. A failed entry leaves the rest running.
delete_candidates() {
	local selected=$1 branch index path failed=0 i
	local -a dirty_branches=() dirty_indexes=()
	while IFS=$'\t' read -r branch index _; do
		[ -n "$branch" ] || continue
		if [ "$index" = branch ]; then
			run git branch -D -- "$branch" || {
				warn "branch retained: $branch"
				failed=1
			}
			continue
		fi
		path=${delete_paths[index]}
		if remove_clean_worktree "$path"; then
			delete_worktree_branch "$branch" "$index" || failed=1
		else
			dirty_branches+=("$branch")
			dirty_indexes+=("$index")
		fi
	done <<<"$selected"
	for i in "${!dirty_indexes[@]}"; do
		index=${dirty_indexes[i]}
		path=${delete_paths[index]}
		if confirm "Force-remove worktree '$path', including uncommitted and untracked files?" &&
			force_remove_worktree "$path"; then
			delete_worktree_branch "${dirty_branches[i]}" "$index" || failed=1
		else
			warn "worktree retained: $path"
			failed=1
		fi
	done
	return "$failed"
}
