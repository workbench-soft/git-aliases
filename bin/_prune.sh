#!/usr/bin/env bash
# Branch and worktree removal behind git db and git dbm. Source _shared.sh first.
#
# read_worktrees fills four arrays, one slot per worktree in `git worktree list`
# order, so slot 0 is the main worktree:
#   wt_path    the folder
#   wt_branch  the branch checked out there, empty when detached
#   wt_head    the commit checked out there
#   wt_locked  1 when `git worktree lock` holds it, else 0

# Prints one picker line per branch or worktree that may go:
#   <branch>  TAB  branch  TAB  [branch]
#   <branch>  TAB  <slot>  TAB  [worktree] <path>
# Mode "gone" keeps branches whose upstream was deleted. Mode "all" keeps every
# branch and adds detached worktrees, with their commit in the first column.
prune_candidates() {
	local mode=$1 here current all_branches gone_list='' branch slot in_worktree
	here=$(git rev-parse --show-toplevel) || return
	current=$(git branch --show-current) || return
	all_branches=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/) || return
	if [[ $mode == gone ]]; then
		gone_list=$(branches_with_gone_upstream) || return
	fi

	while IFS= read -r branch; do
		[[ -n $branch && $branch != "$current" ]] || continue
		if [[ $mode == gone && $'\n'$gone_list$'\n' != *$'\n'"$branch"$'\n'* ]]; then
			continue
		fi
		in_worktree=0
		for slot in "${!wt_path[@]}"; do
			[[ ${wt_branch[slot]} == "$branch" ]] || continue
			in_worktree=1
			worktree_removable "$slot" "$here" || continue
			printf '%s\t%s\t[worktree] %s\n' "$branch" "$slot" "$(one_line "${wt_path[slot]}")"
		done
		((in_worktree)) || printf '%s\tbranch\t[branch]\n' "$branch"
	done <<<"$all_branches"

	[[ $mode == all ]] || return 0
	for slot in "${!wt_path[@]}"; do
		[[ -z ${wt_branch[slot]} ]] || continue
		worktree_removable "$slot" "$here" || continue
		printf '%s\t%s\t[worktree detached] %s\n' "${wt_head[slot]}" "$slot" "$(one_line "${wt_path[slot]}")"
	done
}

# Takes picker lines and removes each one. Clean worktrees and plain branches go
# first. Worktrees with changes wait until the end, then get a question each.
# One failure doesn't stop the rest, and the return code is 1 when anything stays.
prune_selected() {
	local picked=$1 branch slot folder status=0 n
	local -a held_branches=() held_slots=()
	while IFS=$'\t' read -r branch slot _; do
		[[ -n $branch ]] || continue
		if [[ $slot == branch ]]; then
			trace_run git branch -D -- "$branch" || {
				report_warning "branch retained: $branch"
				status=1
			}
			continue
		fi
		folder=${wt_path[slot]}
		if try_remove_worktree "$folder"; then
			drop_worktree_branch "$branch" "$slot" || status=1
		else
			held_branches+=("$branch")
			held_slots+=("$slot")
		fi
	done <<<"$picked"

	for n in "${!held_slots[@]}"; do
		slot=${held_slots[n]}
		folder=${wt_path[slot]}
		if ask_yes "Force-remove worktree '$folder', including uncommitted and untracked files?" &&
			remove_worktree_forced "$folder"; then
			drop_worktree_branch "${held_branches[n]}" "$slot" || status=1
		else
			report_warning "worktree retained: $folder"
			status=1
		fi
	done
	return "$status"
}

# A temp file, unlike a pipe, keeps the exit code of `git worktree list`, and -z
# keeps paths that hold a tab or a newline whole.
read_worktrees() {
	local listing field slot=-1
	listing=$(mktemp) || return
	if ! git worktree list --porcelain -z >"$listing"; then
		rm -f -- "$listing"
		return 1
	fi
	wt_path=() wt_branch=() wt_head=() wt_locked=()
	while IFS= read -r -d '' field; do
		case $field in
			'worktree '*)
				slot=$((slot + 1))
				wt_path[slot]=${field#worktree }
				wt_branch[slot]=''
				wt_head[slot]=''
				wt_locked[slot]=0
				;;
			'branch refs/heads/'*) wt_branch[slot]=${field#branch refs/heads/} ;;
			'HEAD '*) wt_head[slot]=${field#HEAD } ;;
			locked*) wt_locked[slot]=1 ;;
		esac
	done <"$listing"
	rm -f -- "$listing"
}

branches_with_gone_upstream() {
	git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ |
		awk '/\[gone\]/ {print $1}'
}

# The main worktree, the one in use, a locked one and one that holds another
# worktree inside its folder all stay.
worktree_removable() {
	local slot=$1 here=$2 other folder=${wt_path[$1]}
	[[ $slot != 0 && $folder != "$here" && ${wt_locked[slot]} == 0 ]] || return 1
	for other in "${!wt_path[@]}"; do
		[[ $other != "$slot" && ${wt_path[other]} == "$folder"/* ]] && return 1
	done
	return 0
}

# The picker splits on tabs and lines, so the label shows both as spaces.
one_line() {
	local text=${1//$'\t'/ }
	printf '%s\n' "${text//$'\n'/ }"
}

worktree_listed() {
	local field
	while IFS= read -r -d '' field; do
		[[ $field == "worktree $1" ]] && return 0
	done < <(git worktree list --porcelain -z)
	return 1
}

# `git worktree remove` refuses a worktree with changes and leaves it listed.
# When the listing lost it, git found no changes, and only the folder is left.
try_remove_worktree() {
	local folder=$1
	trace_run git worktree remove -- "$folder" && return 0
	worktree_listed "$folder" && return 1
	remove_stale_folder "$folder"
}

remove_worktree_forced() {
	local folder=$1
	trace_run git worktree remove --force -- "$folder" && return 0
	remove_stale_folder "$folder"
	worktree_listed "$folder" || return 0
	trace_run git worktree remove --force -- "$folder"
}

# A dev server can write into the folder while git deletes it. Git then drops
# the worktree from its list and leaves the folder, so this deletes it, with
# up to 3 tries a second apart.
remove_stale_folder() {
	local folder=$1 try holders=''
	for try in 1 2 3; do
		[[ -e $folder ]] || return 0
		((try == 1)) || sleep 1
		trace_run rm -rf -- "$folder" && return 0
	done
	if command -v lsof >/dev/null 2>&1; then
		holders=$(lsof -t +d "$folder" 2>/dev/null | sort -u | tr '\n' ' ') || true
	fi
	report_warning "could not delete '$folder'${holders:+, processes still using it: $holders}"
}

# Another worktree may still have the branch checked out, and then it stays.
drop_worktree_branch() {
	local branch=$1 slot=$2 still_at
	[[ -n ${wt_branch[slot]} ]] || return 0
	still_at=$(git for-each-ref --format='%(worktreepath)' "refs/heads/$branch")
	if [[ -n $still_at ]]; then
		trace "Keeping branch '$branch': still used by worktree '$still_at'"
		return 0
	fi
	trace_run git branch -D -- "$branch" || {
		report_warning "branch retained: $branch"
		return 1
	}
}
