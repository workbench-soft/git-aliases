#!/usr/bin/env bash
# Shared helpers for the git-* scripts next to this file. Not an alias itself.

# shellcheck disable=SC2034  # each script uses a different subset of the colours
if [ -z "${NO_COLOR:-}" ] && { [ -t 1 ] || [ -t 2 ]; }; then
	CLR_OFF=$'\033[0m'
	CLR_COMMAND=$'\033[1;36m'
	CLR_PROMPT=$'\033[1;33m'
	CLR_FAINT=$'\033[38;5;240m'
	CLR_HINT=$'\033[38;5;220m'
else
	CLR_OFF='' CLR_COMMAND='' CLR_PROMPT='' CLR_FAINT='' CLR_HINT=''
fi

# Echo a command the way a shell prompt would, then run it.
trace() {
	printf '%s+%s %s%s%s\n' "$CLR_PROMPT" "$CLR_OFF" "$CLR_COMMAND" "$*" "$CLR_OFF" >&2
}

trace_run() {
	trace "$@"
	"$@"
}

abort() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

report_warning() {
	printf '%swarning:%s %s\n' "$CLR_HINT" "$CLR_OFF" "$*" >&2
}

# How the alias is called: the argument shape, then a line per flag. Exits 1,
# the way git itself answers -h.
show_usage() {
	local name=${0##*/}
	name=${name#git-}
	printf 'usage: git %s %s\n' "$name" "$1" >&2
	shift
	if [ "$#" -gt 0 ]; then
		printf '\n' >&2
		printf '  %s\n' "$@" >&2
	fi
	exit 1
}

# Ask on the terminal, not on stdin, so it works inside a pipeline.
ask_yes() {
	local answer
	printf '%s [y/N] ' "$*" >&2
	read -r answer </dev/tty || return 1
	case $answer in
		y | Y | yes | YES) return 0 ;;
		*) return 1 ;;
	esac
}

need_command() {
	command -v "$1" >/dev/null 2>&1 || abort "$1 is required, but it isn't installed"
}

# origin when it exists, otherwise the only remote there is.
pick_remote() {
	local remotes
	if git remote get-url origin >/dev/null 2>&1; then
		printf 'origin\n'
		return 0
	fi
	remotes=$(git remote)
	if [ "$(printf '%s' "$remotes" | grep -c .)" = 1 ]; then
		printf '%s\n' "$remotes"
		return 0
	fi
	abort 'no remote called origin, and more than one to choose from'
}

# The branch that remote points at, falling back to master then main.
remote_head_branch() {
	local remote=$1 ref branch
	if ref=$(git symbolic-ref --quiet "refs/remotes/$remote/HEAD" 2>/dev/null); then
		printf '%s\n' "${ref#refs/remotes/"$remote"/}"
		return 0
	fi
	for branch in master main; do
		if git show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
			printf '%s\n' "$branch"
			return 0
		fi
	done
	abort "no $remote/HEAD, $remote/master or $remote/main found, run: git remote set-head $remote --auto"
}

log_preview='git log -n 20 --color=always --date=short --pretty=format:"%C(auto)%h %ad %an %s" {1}'
