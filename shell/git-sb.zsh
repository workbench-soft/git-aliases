# Lets `git sb` change the directory of the zsh it runs in.
#
# The branch `git sb` picks may sit in another worktree. A git alias runs as a
# child process, and a child can't cd for its parent. So the alias prints
# "__cd__ <path>", and this function does the cd and moves the VS Code window.
#
# install.sh offers to source this file from ~/.zshrc.

git() {
	[[ $1 == sb ]] || {
		command git "$@"
		return
	}
	shift
	local reply target
	reply=$(command git sb "$@") || return
	[[ $reply == "__cd__ "* ]] || return 0
	target=${reply#__cd__ }
	cd "$target" || return
	if [[ $TERM_PROGRAM == vscode ]] && (($+commands[code])); then
		code -r "$target"
	fi
}
