#!/usr/bin/env bash
# Runs each alias in a scratch repo under a scratch HOME, then checks the result.
# All of it happens inside one temp directory, which goes away at exit.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
on_windows=no
case $(uname -s) in
	MINGW* | MSYS* | CYGWIN*) on_windows=yes ;;
esac

tmp=$(mktemp -d)
# Git for Windows prints C:/... paths, so the expected values use that form too.
if [[ $on_windows == yes ]]; then
	tmp=$(cd "$tmp" && pwd -W)
else
	tmp=$(cd "$tmp" && pwd -P)
fi
trap 'rm -rf "$tmp"' EXIT

total=0
failures=0

record_pass() { total=$((total + 1)); }

record_failure() {
	total=$((total + 1))
	failures=$((failures + 1))
	printf 'FAIL %s\n' "$1" >&2
	printf '  expected: %s\n' "$2" >&2
	printf '  actual:   %s\n' "$3" >&2
}

expect_eq() {
	if [[ $2 == "$3" ]]; then record_pass; else record_failure "$1" "$2" "$3"; fi
}

expect_in() {
	if [[ $3 == *"$2"* ]]; then record_pass; else record_failure "$1" "output containing '$2'" "$3"; fi
}

# Runs the command after the label and the fragment. It passes when the command
# exits non-zero and its output holds the fragment.
expect_refusal() {
	local label=$1 fragment=$2 output code=0
	shift 2
	output=$("$@" 2>&1) || code=$?
	if ((code == 0)); then
		record_failure "$label" 'a non-zero exit' 'exit 0'
	else
		expect_in "$label" "$fragment" "$output"
	fi
}

exists() {
	if [[ -e $1 ]]; then echo yes; else echo no; fi
}

# --- a git that knows these aliases and nothing else ------------------------

export HOME="$tmp/home"
export NO_COLOR=1
unset XDG_CONFIG_HOME
mkdir -p "$HOME"

git config --global gitaliases.dir "$repo"
git config --global include.path "$repo/aliases.gitconfig"
git config --global user.name 'Test User'
git config --global user.email 'test@example.com'
git config --global commit.gpgsign false
git config --global init.defaultBranch main

git init -q --bare "$tmp/origin.git"
git clone -q "$tmp/origin.git" "$tmp/work" 2>/dev/null
cd "$tmp/work"

echo one >file.txt
git add -A
git commit -qm 'init'
git push -q -u origin main
git remote set-head origin --auto >/dev/null

# --- one alias at a time ----------------------------------------------------

expect_eq 'git b names the branch' main "$(git b)"

git cb 'Feature X!' >/dev/null 2>&1
expect_eq 'git cb turns the name into a slug' feature-x "$(git b)"
git checkout -q main
git cb '--Odd..Name/.x.' >/dev/null 2>&1
expect_eq 'git cb drops the dots git refuses' odd.name/x "$(git b)"
git checkout -q main
git cb 'Update yarn.lock.' >/dev/null 2>&1
expect_eq 'git cb renames a .lock ending git refuses' update-yarn-lock "$(git b)"
git checkout -q feature-x

expect_refusal 'git c refuses an empty message' 'usage: git c' git c

for alias_name in c cb co cp r; do
	expect_refusal "git $alias_name -h prints the usage" "usage: git $alias_name" git "$alias_name" -h
done

for alias_name in cb co cp; do
	expect_refusal "git $alias_name with no arguments prints the usage" "usage: git $alias_name" git "$alias_name"
done

git init -q "$tmp/no-remote"
expect_refusal 'an alias in a repo with no remote says so' 'no remote set up' git -C "$tmp/no-remote" master
expect_refusal 'git r -h works in a repo with no remote' 'usage: git r' git -C "$tmp/no-remote" r -h

expect_in 'the usage lists each flag' '-f  push with --force-with-lease' "$(git cp -h 2>&1 || true)"

echo two >>file.txt
git add -A
git c fixed the file >/dev/null 2>&1
expect_eq 'git c joins its words into the message' 'fixed the file' "$(git log -1 --format=%s)"

echo three >>file.txt
git add -A
git c -- -fixed with a dash >/dev/null 2>&1
expect_eq 'git c keeps a leading dash after --' '-fixed with a dash' "$(git log -1 --format=%s)"
git reset -q --soft HEAD~1

expect_in 'git last prints the last commit' 'fixed the file' "$(git last)"

git sr1 >/dev/null 2>&1
expect_eq 'git sr1 removes the last commit' 'init' "$(git log -1 --format=%s)"
expect_eq 'git sr1 leaves its change staged' 'file.txt' "$(git diff --cached --name-only)"

git cp -s second commit >/dev/null 2>&1
expect_eq 'git cp makes the commit' 'second commit' "$(git log -1 --format=%s)"
expect_eq 'git cp pushes the commit' 'second commit' "$(git -C "$tmp/origin.git" log -1 --format=%s feature-x)"

echo junk >junk.txt
git hr >/dev/null 2>&1
expect_eq 'git hr removes untracked files' no "$(exists junk.txt)"

git srmb >/dev/null 2>&1
expect_eq 'git srmb moves HEAD to the merge base' "$(git rev-parse origin/main)" "$(git rev-parse HEAD)"

git reset -q --hard
git master >/dev/null 2>&1
expect_eq 'git master lands on the default branch' main "$(git b)"

git worktree add -q -b master-elsewhere "$tmp/master-elsewhere"
echo keep >"$tmp/master-elsewhere/keep.txt"
expect_refusal 'git master names the worktree that holds the default branch' "main is checked out at $tmp/work" git -C "$tmp/master-elsewhere" master
expect_eq 'git master there keeps the local changes' yes "$(exists "$tmp/master-elsewhere/keep.txt")"
git worktree remove --force "$tmp/master-elsewhere"
git branch -q -D master-elsewhere

# A copy of the alias, with a stub in place of the terminal question.
mkdir -p "$tmp/master-alias/bin"
cp "$repo/bin/git-master" "$repo/bin/_shared.sh" "$tmp/master-alias/bin/"
# shellcheck disable=SC2016
echo 'ask_yes() { [[ ${answer_yes:-no} == yes ]]; }' >>"$tmp/master-alias/bin/_shared.sh"
git commit -q --allow-empty -m 'local only'
expect_refusal 'git master lists the commits it would drop' 'local only' git -c gitaliases.dir="$tmp/master-alias" master
expect_eq 'a no keeps the local commit' 'local only' "$(git log -1 --format=%s)"
answer_yes=yes git -c gitaliases.dir="$tmp/master-alias" master >/dev/null 2>&1
expect_eq 'a yes resets to the remote' "$(git rev-parse origin/main)" "$(git rev-parse HEAD)"

git co feature-x >/dev/null 2>&1
expect_eq 'git co switches to a local branch' feature-x "$(git b)"

git clone -q "$tmp/origin.git" "$tmp/elsewhere"
git -C "$tmp/elsewhere" checkout -q -b remote-only
git -C "$tmp/elsewhere" commit -q --allow-empty -m 'made elsewhere'
git -C "$tmp/elsewhere" push -q -u origin remote-only

git co remote-only >/dev/null 2>&1
expect_eq 'git co fetches a branch only the remote has' remote-only "$(git b)"

git checkout -q main
git r >/dev/null 2>&1
expect_eq 'git r keeps an up to date branch where it is' "$(git rev-parse origin/main)" "$(git rev-parse HEAD)"

git p >/dev/null 2>&1
expect_eq 'git p keeps an up to date branch where it is' "$(git rev-parse origin/main)" "$(git rev-parse HEAD)"

expect_in 'git dbm reports an empty list' 'No deletable branches or worktrees with a gone upstream.' "$(git dbm 2>&1)"

# --- deleting branches and worktrees ----------------------------------------

# shellcheck source=bin/_shared.sh
. "$repo/bin/_shared.sh"
# shellcheck source=bin/_prune.sh
. "$repo/bin/_prune.sh"

# The stubs read scratch, since an exported tmp clashes with TMP on Windows.
# ask_yes logs each question and answers with $answer_yes.
ask_yes() {
	printf '%s\n' "$*" >>"$scratch/questions"
	[[ ${answer_yes:-no} == yes ]]
}

# fzf saves the menu it got, then picks the lines whose branch is in $pick.
fzf() {
	local menu
	menu=$(cat)
	printf '%s\n' "$menu" >"$scratch/menu"
	printf '%s\n' "$menu" | awk -F'\t' 'index("\n" ENVIRON["pick"] "\n", "\n" $1 "\n")'
}
export -f fzf
export scratch=$tmp

git branch delete-plain
git worktree add -q -b delete-clean "$tmp/clean worktree"
git worktree add -q -b delete-dirty "$tmp/dirty"
git worktree add -q -b delete-locked "$tmp/locked"
git worktree lock "$tmp/locked"
git worktree add -q --detach "$tmp/detached"
git worktree add -q -b delete-missing "$tmp/missing"
# NTFS rejects a tab or a newline in a folder name.
if [[ $on_windows == no ]]; then
	git worktree add -q -b delete-odd "$tmp/odd"$'\t\n'"path"
fi
git config branch.delete-clean.description 'private branch setting'
clean_gitdir=$(git -C "$tmp/clean worktree" rev-parse --absolute-git-dir)
echo dirty >>"$tmp/dirty/file.txt"
echo untracked >"$tmp/dirty/untracked.txt"
echo ignored >"$tmp/dirty/ignored.cache"
echo '*.cache' >>.git/info/exclude
echo ignored >"$tmp/clean worktree/ignored.cache"
echo shared-stash >>file.txt
git stash push -qm shared-stash
stash_before=$(git rev-parse refs/stash)

read_worktrees
menu=$(prune_candidates all)
expect_in 'the menu marks a plain branch' $'delete-plain\tbranch\t[branch]' "$menu"
expect_in 'the menu marks a worktree and shows its path' "[worktree] $tmp/clean worktree" "$menu"
expect_in 'the menu offers detached worktrees' '[worktree detached]' "$menu"
expect_eq 'the menu leaves out locked worktrees' '' "$(grep -F delete-locked <<<"$menu" || true)"
expect_eq 'the menu leaves out the current branch' '' "$(awk -F'\t' '$1 == "main"' <<<"$menu")"
menu_from_linked=$(cd "$tmp/dirty" && read_worktrees && prune_candidates all)
expect_eq 'from a linked worktree the menu leaves out the main one' '' "$(awk -F'\t' '$1 == "main"' <<<"$menu_from_linked")"
expect_eq 'from a linked worktree the menu leaves out that worktree' '' "$(grep -F delete-dirty <<<"$menu_from_linked" || true)"
menu_from_detached=$(cd "$tmp/detached" && read_worktrees && prune_candidates all)
expect_eq 'from a detached worktree the menu leaves out that worktree' '' "$(grep -F '[worktree detached]' <<<"$menu_from_detached" || true)"

export pick=$'delete-clean\ndelete-plain'
git db >"$tmp/out" 2>&1
expect_eq 'git db deletes the worktree folder' no "$(exists "$tmp/clean worktree")"
expect_eq 'git db deletes the worktree metadata in .git' no "$(exists "$clean_gitdir")"
expect_eq 'git db deletes the branch ref' '' "$(git branch --list delete-clean)"
expect_eq 'git db deletes the branch config' '' "$(git config --get branch.delete-clean.description || true)"
expect_eq 'git db deletes the branch reflog' no "$(git reflog exists refs/heads/delete-clean && echo yes || echo no)"
expect_in 'git db hands fzf the labelled lines' '[branch]' "$(<"$tmp/menu")"
expect_eq 'git db deletes a plain branch picked with the rest' '' "$(git branch --list delete-plain)"

read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-dirty"')
# shellcheck disable=SC2016
expect_refusal 'a worktree with changes waits for a yes' 'worktree retained:' bash -c '
	. "$1/bin/_shared.sh"
	. "$1/bin/_prune.sh"
	ask_yes() { return 1; }
	read_worktrees
	prune_selected "$2"
' bash "$repo" "$picked"
expect_eq 'a no keeps the changed files' dirty "$(tail -n 1 "$tmp/dirty/file.txt")"
expect_in 'a no keeps the branch' 'delete-dirty' "$(git branch --list delete-dirty)"
answer_yes=yes
prune_selected "$picked" >"$tmp/out" 2>&1
expect_in 'the force question warns that files go' 'including uncommitted and untracked files?' "$(<"$tmp/questions")"
expect_eq 'a yes deletes the folder, ignored files too' no "$(exists "$tmp/dirty")"
expect_eq 'a yes deletes the branch' '' "$(git branch --list delete-dirty)"

# Acts like a dev server: git drops the worktree, then a new file makes it fail.
git() {
	local last
	for last; do :; done
	if [[ "${1:-} ${2:-}" == 'worktree remove' && $last == "${busy:-}" ]]; then
		command git "$@" || return
		mkdir -p "$last/.vite"
		echo "error: failed to delete '$last': Directory not empty" >&2
		return 1
	fi
	command git "$@"
}
git worktree add -q -b delete-busy-clean "$tmp/busy-clean"
busy="$tmp/busy-clean"
: >"$tmp/questions"
answer_yes=no
read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-busy-clean"')
prune_selected "$picked" >"$tmp/out" 2>&1
expect_eq 'a clean folder that refills goes without a question' '' "$(<"$tmp/questions")"
expect_eq 'a clean folder that refills is deleted' no "$(exists "$tmp/busy-clean")"
expect_eq 'a clean folder that refills loses its branch' '' "$(git branch --list delete-busy-clean)"

git worktree add -q -b delete-busy "$tmp/busy"
git worktree add -q -b delete-after-busy "$tmp/after-busy"
echo untracked >"$tmp/busy/untracked.txt"
busy="$tmp/busy"
answer_yes=yes
read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-busy" || $1 == "delete-after-busy"')
prune_selected "$picked" >"$tmp/out" 2>&1
expect_eq 'a changed folder that refills is deleted' no "$(exists "$tmp/busy")"
expect_eq 'a changed folder that refills loses its branch' '' "$(git branch --list delete-busy)"
expect_eq 'the entry after a refilled folder still goes' '' "$(git branch --list delete-after-busy)"

git worktree add -q -b delete-stuck "$tmp/stuck"
echo untracked >"$tmp/stuck/untracked.txt"
busy="$tmp/stuck"
rm() {
	if [[ ${3:-} == "$tmp/stuck" ]]; then
		echo "rm: $3: Directory not empty" >&2
		return 1
	fi
	command rm "$@"
}
read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-stuck"')
prune_selected "$picked" >"$tmp/out" 2>&1
unset -f git rm
expect_in 'a folder that stays busy gets a warning' "warning: could not delete '$tmp/stuck'" "$(<"$tmp/out")"
expect_eq 'a folder that stays busy still loses its branch' '' "$(git branch --list delete-stuck)"
rm -rf "$tmp/stuck"

git worktree add -q -b order-dirty "$tmp/order-dirty"
echo untracked >"$tmp/order-dirty/untracked.txt"
git worktree add -q -b order-clean "$tmp/order-clean"
git branch order-plain
read_worktrees
picked=$'no-such-branch\tbranch\t[branch]\n'$(prune_candidates all | awk -F'\t' '$1 ~ /^order-/')
code=0
(
	ask_yes() {
		printf 'clean=%s plain=%s\n' "$(exists "$tmp/order-clean")" "$(git branch --list order-plain)" >"$tmp/order-state"
	}
	prune_selected "$picked"
) >"$tmp/out" 2>&1 || code=$?
expect_eq 'the questions wait until the rest is deleted' 'clean=no plain=' "$(<"$tmp/order-state")"
expect_eq 'one failed entry leaves the rest deleted' '' "$(git branch --list 'order-*')"
expect_eq 'one failed entry makes the exit code 1' 1 "$code"
expect_in 'the failed entry is named' 'branch retained: no-such-branch' "$(<"$tmp/out")"

read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$3 ~ /^\[worktree detached\]/ || $1 == "delete-odd"')
prune_selected "$picked" >"$tmp/out" 2>&1
expect_eq 'the detached worktree folder is deleted' no "$(exists "$tmp/detached")"
if [[ $on_windows == no ]]; then
	expect_eq 'a path with a tab and a newline is deleted' no "$(exists "$tmp/odd"$'\t\n'"path")"
fi
expect_eq 'deleting a detached worktree leaves the current branch' main "$(git b)"

command rm "$tmp/missing/file.txt" "$tmp/missing/.git"
rmdir "$tmp/missing"
export pick=delete-missing
git db >"$tmp/out" 2>&1
expect_eq 'git db clears a worktree whose folder is gone, and its branch' '' "$(git branch --list delete-missing)"

git worktree add -q -b delete-shared "$tmp/shared-a"
git worktree add -q --force "$tmp/shared-b" delete-shared
read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-shared" && !seen++')
prune_selected "$picked" >"$tmp/out" 2>&1
expect_in 'a branch another worktree holds survives' 'delete-shared' "$(git branch --list delete-shared)"
read_worktrees
picked=$(prune_candidates all | awk -F'\t' '$1 == "delete-shared"')
prune_selected "$picked" >"$tmp/out" 2>&1
expect_eq 'the branch goes with its last worktree' '' "$(git branch --list delete-shared)"

git worktree add -q -b delete-parent "$tmp/parent"
git worktree add -q -b delete-child "$tmp/parent/child"
read_worktrees
menu=$(prune_candidates all)
expect_eq 'the menu leaves out a folder with a worktree inside' '' "$(awk -F'\t' '$1 == "delete-parent"' <<<"$menu")"
expect_in 'the menu offers the inner worktree' 'delete-child' "$menu"

git branch gone-plain
git worktree add -q -b gone-worktree "$tmp/gone"
git worktree add -q -b kept-worktree "$tmp/kept"
for branch in gone-plain gone-worktree delete-locked main; do
	git push -q origin "$branch:refs/heads/upstream-$branch"
	git branch --set-upstream-to="origin/upstream-$branch" "$branch" >/dev/null
	git push -q origin --delete "upstream-$branch"
done
git branch --set-upstream-to=origin/main kept-worktree >/dev/null
read_worktrees
picked=$(prune_candidates gone)
expect_in 'the dbm list holds plain branches' $'gone-plain\tbranch\t[branch]' "$picked"
expect_in 'the dbm list holds worktrees' "[worktree] $tmp/gone" "$picked"
expect_eq 'the dbm list leaves out locked worktrees' '' "$(grep -F delete-locked <<<"$picked" || true)"
expect_eq 'the dbm list leaves out the current branch' '' "$(awk -F'\t' '$1 == "main"' <<<"$picked")"
expect_eq 'the dbm list leaves out branches whose upstream exists' '' "$(grep -F kept-worktree <<<"$picked" || true)"
git branch prune-only
git push -qu origin prune-only
git --git-dir="$tmp/origin.git" update-ref -d refs/heads/prune-only
# A copy of the alias, with the stub in place of the terminal question.
mkdir -p "$tmp/aliases/bin"
cp "$repo/bin/git-dbm" "$repo/bin/_shared.sh" "$repo/bin/_prune.sh" "$tmp/aliases/bin/"
declare -f ask_yes >>"$tmp/aliases/bin/_prune.sh"
export answer_yes=yes
git -c gitaliases.dir="$tmp/aliases" dbm >"$tmp/out" 2>&1
expect_in 'git dbm prints the branch labels' 'gone-plain [branch]' "$(<"$tmp/out")"
expect_in 'git dbm prints the worktree labels' "gone-worktree [worktree] $tmp/gone" "$(<"$tmp/out")"
expect_eq 'git dbm deletes the gone branches' '' "$(git branch --list 'gone-*')"
expect_eq 'git dbm prunes before it builds the list' '' "$(git branch --list prune-only)"
expect_eq 'git dbm deletes the gone worktree folders' no "$(exists "$tmp/gone")"
expect_eq 'git dbm leaves the locked worktree files' yes "$(exists "$tmp/locked/file.txt")"
expect_eq 'git dbm leaves a worktree whose upstream exists' yes "$(exists "$tmp/kept/file.txt")"
expect_eq 'removing worktrees keeps the shared stash' "$stash_before" "$(git rev-parse refs/stash)"

git branch --set-upstream-to=origin/main main >/dev/null

# fzf saves the menu it got, then picks the line that starts with $pick.
sb_out=$(
	# shellcheck disable=SC2329  # git sb calls it through export -f
	fzf() {
		local menu
		menu=$(cat)
		printf '%s\n' "$menu" >"$scratch/menu"
		printf '%s\n' "$menu" | grep -m 1 "^$pick "
	}
	export -f fzf
	pick=kept-worktree git sb 2>/dev/null
)
expect_eq 'git sb prints the folder of a branch in another worktree' "__cd__ $tmp/kept" "$sb_out"
expect_in 'git sb marks the branch of this worktree' '(this worktree)' "$(<"$tmp/menu")"
expect_eq 'git sb leaves colour out of its menu under NO_COLOR' '' "$(grep -F $'\033' "$tmp/menu" || true)"

# --- the installer ----------------------------------------------------------

# Git Bash spells HOME as /c/Users/..., so the scratch HOME does too.
install_home="$tmp/install-home"
mkdir -p "$install_home"
if [[ $on_windows == yes ]]; then
	install_home=$(cygpath -u "$install_home")
fi
printf '[alias]\n\tco = checkout\n' >"$install_home/.gitconfig"
install_out=$(
	export HOME=$install_home
	# shellcheck source=/dev/null  # its repo and index stay inside this subshell
	. "$repo/install.sh"
	# shellcheck disable=SC2329  # offer_alias_cleanup calls it
	ask_yes() { printf 'asked: %s\n' "$*"; }
	offer_alias_cleanup
	link_aliases >/dev/null
	link_aliases >/dev/null
	printf 'include.path count: %s\n' "$(git config --global --get-all include.path | grep -c .)"
)
expect_in 'install.sh offers to remove an alias ~/.gitconfig sets itself' 'asked: Remove the [alias] section' "$install_out"
expect_in 'a second install.sh run keeps one include.path' 'include.path count: 1' "$install_out"

alias_total=$(git config --file "$repo/aliases.gitconfig" --name-only --get-regexp '^alias\.' | grep -c .)
expect_eq 'git a lists each alias' "$alias_total" "$(git a | grep -c 'bin/git-')"

# ----------------------------------------------------------------------------

if ((failures)); then
	printf '\n%d of %d checks failed\n' "$failures" "$total" >&2
	exit 1
fi

printf 'ok: %d checks\n' "$total"
