# Lets `git sb` change the directory of the PowerShell it runs in.
#
# The branch `git sb` picks may sit in another worktree. A git alias runs as a
# child process, and a child can't cd for its parent. So the alias prints
# "__cd__ <path>", and this function does the cd and moves the VS Code window.
#
# install.ps1 offers to dot-source this file from $PROFILE.

function git {
	$gitExe = Get-Command git -CommandType Application | Select-Object -First 1
	if ($args.Count -eq 0 -or $args[0] -ne 'sb') {
		& $gitExe @args
		return
	}

	$sbArgs = @($args | Select-Object -Skip 1)
	$reply = @(& $gitExe sb @sbArgs)
	$code = $LASTEXITCODE
	# git checkout prints lines such as "Your branch is up to date" on stdout.
	$reply | Where-Object { $_ -notlike '__cd__ *' }
	$cdLine = $reply | Where-Object { $_ -like '__cd__ *' } | Select-Object -First 1
	if ($code -ne 0 -or -not $cdLine) { return }

	$target = $cdLine.Substring(7)
	Set-Location -LiteralPath $target
	if ($env:TERM_PROGRAM -eq 'vscode' -and (Get-Command code -ErrorAction SilentlyContinue)) {
		code -r $target
	}
}
