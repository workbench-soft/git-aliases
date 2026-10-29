#!/usr/bin/env bash
# Fails when the repo drifts from its rules: each alias runs a bin/ script, each
# script describes itself and has an alias and a README row, and the shell is clean.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
cd "$repo"

index='aliases.gitconfig'
readme='README.md'
# shellcheck disable=SC2016  # the alias text itself, which git expands later
alias_prefix='!"$(git config gitaliases.dir)"/bin/'
chmod_hint='run chmod +x, or on Windows git update-index --chmod=+x'

problems=0
alias_names=()
alias_scripts=()

main() {
	check_index
	check_scripts
	check_readme
	run_shellcheck
	run_shfmt
	parse_powershell

	if ((problems)); then
		printf '\n%d problem(s)\n' "$problems" >&2
		exit 1
	fi
	printf 'ok: %d aliases, %d scripts\n' "${#alias_names[@]}" "$(count_scripts)"
}

problem() {
	printf 'FAIL %s\n' "$*" >&2
	problems=$((problems + 1))
}

# NTFS has no exec bit, so a tracked file goes by the mode git stored for it.
is_executable() {
	local mode
	mode=$(git ls-files --stage -- "$1" | cut -c1-6)
	if [[ -n $mode ]]; then
		[[ $mode == 100755 ]]
	else
		[[ -x $1 ]]
	fi
}

count_scripts() {
	local scripts=(bin/git-*)
	printf '%d\n' "${#scripts[@]}"
}

# Reads each alias, checks it runs bin/git-<script>, and keeps the name and the
# script for the later checks.
check_index() {
	local entry alias_name command script line
	while IFS= read -r -d '' entry; do
		alias_name=${entry%%$'\n'*}
		alias_name=${alias_name#alias.}
		command=${entry#*$'\n'}

		if [[ $command != "$alias_prefix"* ]]; then
			problem "$index: alias '$alias_name' does not run a bin/ script: $command"
			continue
		fi
		script=${command#"$alias_prefix"}
		if [[ ! $script =~ ^git-[a-z0-9-]+$ ]]; then
			problem "$index: alias '$alias_name' has an odd script name: $script"
			continue
		fi
		[[ -f bin/$script ]] || problem "$index: alias '$alias_name' points at missing bin/$script"

		alias_names+=("$alias_name")
		alias_scripts+=("$script")
	done < <(git config --file "$index" --null --get-regexp '^alias\.')

	((${#alias_names[@]})) || problem "$index: no aliases found"

	local listed
	listed=$(printf '%s\n' ${alias_names[@]+"${alias_names[@]}"})
	[[ $listed == "$(LC_ALL=C sort <<<"$listed")" ]] || problem "$index: aliases are not sorted alphabetically"

	while IFS= read -r line; do
		case $line in
			'' | '#'* | '[alias]' | $'\t'*' = "!'*'"') ;;
			*) problem "$index: line is not <tab>name = \"!...\": $line" ;;
		esac
	done <"$index"
}

check_scripts() {
	local script helper entry
	for script in bin/git-*; do
		is_executable "$script" || problem "$script: not executable, $chmod_hint"
		[[ $(head -n 1 "$script") == '#!/usr/bin/env bash' ]] || problem "$script: first line must be #!/usr/bin/env bash"
		[[ $(sed -n '2p' "$script") == '# '?* ]] || problem "$script: line 2 must be a '# ' description comment"
		grep -qx 'set -euo pipefail' "$script" || problem "$script: missing 'set -euo pipefail'"
		is_aliased "${script#bin/}" || problem "$script: no alias in $index runs it"
	done

	for helper in bin/_*.sh; do
		! is_executable "$helper" || problem "$helper: sourced, not run, so it should not be executable"
	done

	for entry in install.sh lint.sh test.sh hooks/pre-commit; do
		is_executable "$entry" || problem "$entry: not executable, $chmod_hint"
	done
}

is_aliased() {
	local used
	for used in ${alias_scripts[@]+"${alias_scripts[@]}"}; do
		[[ $used == "$1" ]] && return 0
	done
	return 1
}

check_readme() {
	local alias_name
	for alias_name in ${alias_names[@]+"${alias_names[@]}"}; do
		grep -qF "\`$alias_name\`" "$readme" || problem "$readme: alias '$alias_name' is not documented"
	done
}

run_shellcheck() {
	if ! command -v shellcheck >/dev/null 2>&1; then
		echo 'skipped shellcheck (not installed: brew install shellcheck)'
		return 0
	fi
	shellcheck --external-sources bin/* ./*.sh hooks/* || problem 'shellcheck reported problems'
}

run_shfmt() {
	if ! command -v shfmt >/dev/null 2>&1; then
		echo 'skipped shfmt (not installed: brew install shfmt)'
		return 0
	fi
	shfmt --diff --case-indent bin/* ./*.sh hooks/* ||
		problem 'shfmt reported formatting problems, run: shfmt --write --case-indent bin/* ./*.sh hooks/*'
}

# PowerShell 7 comes first, then Windows PowerShell.
parse_powershell() {
	local shell_exe='' candidate file
	for candidate in pwsh powershell; do
		command -v "$candidate" >/dev/null 2>&1 || continue
		shell_exe=$candidate
		break
	done
	if [[ -z $shell_exe ]]; then
		echo 'skipped the PowerShell parse (not installed: brew install powershell)'
		return 0
	fi
	for file in ./*.ps1 shell/*.ps1; do
		# shellcheck disable=SC2016  # PowerShell expands these, bash must not
		ps1_file=$file "$shell_exe" -NoProfile -Command '$errors = $null
			$path = (Resolve-Path -LiteralPath $env:ps1_file).Path
			[void][System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
			$errors | ForEach-Object { "$($_.Extent.StartLineNumber): $($_.Message)" }
			exit $errors.Count' || problem "$file: PowerShell can't parse it"
	done
}

main
