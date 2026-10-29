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
	$reply = & $gitExe sb @sbArgs
	if ($LASTEXITCODE -ne 0) { return }
	$cdLine = @($reply) | Where-Object { $_ -like '__cd__ *' } | Select-Object -First 1
	if (-not $cdLine) { return }

	$target = $cdLine.Substring(7)
	Set-Location -LiteralPath $target
	if ($env:TERM_PROGRAM -eq 'vscode' -and (Get-Command code -ErrorAction SilentlyContinue)) {
		code -r $target
	}
}
