#!/usr/bin/env bash
# Hooks this checkout into the global git config on macOS and Linux. A rerun is
# safe: each change waits for a yes, each edited file gets a copy first, and
# ~/.zshrc only grows.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=bin/_shared.sh
. "$repo/bin/_shared.sh"
index="$repo/aliases.gitconfig"
user_gitconfig="$HOME/.gitconfig"
zshrc="$HOME/.zshrc"
zsh_line="source \"$repo/shell/git-sb.zsh\""

main() {
	echo "Installing from $repo"
	echo
	warn_old_git
	chmod +x "$repo"/bin/git-* "$repo/lint.sh" "$repo/hooks/pre-commit"
	offer_alias_cleanup
	link_aliases
	offer_zsh_wrapper
	command -v fzf >/dev/null 2>&1 || echo 'note: git sb and git db need fzf: brew install fzf'
	echo
	git -C "$repo" config core.hooksPath hooks
	prove_install
}

keep_copy() {
	[[ -f $1 ]] || return 0
	local copy
	copy="$1.bak.$(date +%Y%m%d%H%M%S)"
	cp "$1" "$copy"
	echo "  backup: $copy"
}

# git b and git p rely on `git branch --show-current`, added in git 2.22.
warn_old_git() {
	local major minor
	read -r major minor <<<"$(git version | sed -E 's/[^0-9]*([0-9]+)\.([0-9]+).*/\1 \2/')"
	if ((major < 2 || (major == 2 && minor < 22))); then
		echo "warning: git $major.$minor is old, git b and git p need 2.22 for --show-current"
		echo
	fi
}

# An alias set in ~/.gitconfig itself beats the same alias from an include.
offer_alias_cleanup() {
	local ours theirs clashes alias_name
	ours=$(git config --file "$index" --name-only --get-regexp '^alias\.' | sed 's/^alias\.//' | LC_ALL=C sort)
	theirs=$(git config --global --show-origin --name-only --get-regexp '^alias\.' 2>/dev/null |
		awk -F'\t' -v origin="file:$user_gitconfig" '$1 == origin {sub(/^alias\./, "", $2); print $2}' |
		LC_ALL=C sort -u || true)
	clashes=$(comm -12 <(printf '%s\n' "$ours") <(printf '%s\n' "$theirs") || true)
	[[ -n $clashes ]] || return 0

	echo 'Your ~/.gitconfig defines these aliases itself, so they would shadow the repo:'
	while IFS= read -r alias_name; do
		echo "  $alias_name"
	done <<<"$clashes"
	if ask_yes 'Remove the [alias] section from ~/.gitconfig?'; then
		keep_copy "$user_gitconfig"
		git config --global --remove-section alias
		echo '  removed'
	else
		echo '  left as is, so the repo aliases stay shadowed'
	fi
	echo
}

link_aliases() {
	git config --global gitaliases.dir "$repo"
	echo "gitaliases.dir = $repo"
	if git config --global --get-all include.path 2>/dev/null | grep -qxF "$index"; then
		echo "include.path already has $index"
	else
		git config --global --add include.path "$index"
		echo "include.path += $index"
	fi
	echo
}

# git sb prints "__cd__ <path>", and the zsh function turns it into a cd.
offer_zsh_wrapper() {
	local line_no
	if [[ -f $zshrc ]] && grep -qF 'shell/git-sb.zsh' "$zshrc"; then
		echo 'zsh: already sources shell/git-sb.zsh'
	elif [[ -f $zshrc ]] && grep -qF '__cd__' "$zshrc"; then
		line_no=$(grep -nF '__cd__' "$zshrc" | head -1 | cut -d: -f1)
		echo "zsh: ~/.zshrc has its own copy of the wrapper, around line $line_no."
		if ask_yes '     Append the repo version, so the repo becomes the single source?'; then
			keep_copy "$zshrc"
			printf '\n# git-aliases, replaces the older git() wrapper above\n%s\n' "$zsh_line" >>"$zshrc"
			echo '  appended, the old block is now dead code you can delete'
			echo '  pick it up with: exec zsh'
		else
			echo '  left as is'
		fi
	elif ask_yes 'zsh: let git sb change directory by sourcing it from ~/.zshrc?'; then
		keep_copy "$zshrc"
		printf '\n# git-aliases\n%s\n' "$zsh_line" >>"$zshrc"
		echo '  added, pick it up with: exec zsh'
	else
		echo "zsh: skipped, add this to ~/.zshrc yourself: $zsh_line"
	fi
}

prove_install() {
	if git -C "$repo" a >/dev/null 2>&1; then
		echo 'Done. Run: git a'
	else
		echo 'Something is off: git a does not run. Check include.path in ~/.gitconfig.' >&2
		exit 1
	fi
}

main
