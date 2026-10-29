#!/usr/bin/env bash
# Sourced by every git-* script beside it. It holds no alias of its own.
# shellcheck disable=SC2034  # each script reads only some of the colours

# Colour goes to a terminal only, and NO_COLOR turns it off.
if [[ -z ${NO_COLOR:-} ]] && [[ -t 1 || -t 2 ]]; then
	CLR_OFF=$'\033[0m'
	CLR_COMMAND=$'\033[1;36m'
	CLR_PROMPT=$'\033[1;33m'
	CLR_FAINT=$'\033[38;5;240m'
	CLR_HINT=$'\033[38;5;220m'
else
	CLR_OFF='' CLR_COMMAND='' CLR_PROMPT='' CLR_FAINT='' CLR_HINT=''
fi

# fzf fills {1} with the branch of the highlighted line.
log_preview='git log -n 20 --color=always --date=short --pretty=format:"%C(auto)%h %ad %an %s" {1}'

# Prints "+ <command>" on stderr, as a shell with xtrace would.
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

# Prints the synopsis in $1 and one line per later argument, then exits 1
# the way git does for -h.
show_usage() {
	local alias_name=${0##*/}
	alias_name=${alias_name#git-}
	printf 'usage: git %s %s\n' "$alias_name" "$1" >&2
	shift
	if (($#)); then
		printf '\n' >&2
		printf '  %s\n' "$@" >&2
	fi
	exit 1
}

# Reads the answer from the terminal, so a pipe on stdin can't answer for the person.
ask_yes() {
	local reply
	printf '%s [y/N] ' "$*" >&2
	read -r reply </dev/tty || return 1
	case $reply in
		y | Y | yes | YES) return 0 ;;
		*) return 1 ;;
	esac
}

need_command() {
	command -v "$1" >/dev/null 2>&1 || abort "$1 is required, but it isn't installed"
}

# Prints origin, or the single remote when origin is missing.
pick_remote() {
	git remote get-url origin >/dev/null 2>&1 && {
		printf 'origin\n'
		return 0
	}
	local all_remotes count
	all_remotes=$(git remote)
	count=$(printf '%s' "$all_remotes" | grep -c . || true)
	case $count in
		0) abort 'no remote set up, add one with: git remote add origin <url>' ;;
		1) printf '%s\n' "$all_remotes" ;;
		*) abort 'no remote called origin, and more than one to choose from' ;;
	esac
}

# Prints the branch <remote>/HEAD names. Without it, master, then main.
remote_head_branch() {
	local remote=$1 head_ref fallback
	if head_ref=$(git symbolic-ref --quiet "refs/remotes/$remote/HEAD" 2>/dev/null); then
		printf '%s\n' "${head_ref#refs/remotes/"$remote"/}"
		return 0
	fi
	for fallback in master main; do
		git show-ref --verify --quiet "refs/remotes/$remote/$fallback" || continue
		printf '%s\n' "$fallback"
		return 0
	done
	abort "no $remote/HEAD, $remote/master or $remote/main found, run: git remote set-head $remote --auto"
}
