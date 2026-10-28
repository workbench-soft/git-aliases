# Makes `git sb` able to change directory in PowerShell.
#
# `git sb` may pick a branch that lives in another worktree. A git alias runs in
# a subprocess and can't move the parent shell, so it prints "__cd__ <path>" and
# this wrapper does the cd, then points the VS Code window at the same place.
#
# install.ps1 offers to dot-source this file from $PROFILE.

function git {
	$gitExe = Get-Command git -CommandType Application | Select-Object -First 1
	if ($args.Count -gt 0 -and $args[0] -eq 'sb') {
		$rest = @($args | Select-Object -Skip 1)
		$out = & $gitExe sb @rest
		if ($LASTEXITCODE -ne 0) { return }
		$line = @($out) | Where-Object { $_ -like '__cd__ *' } | Select-Object -First 1
		if ($line) {
			$dir = $line.Substring(7)
			Set-Location -LiteralPath $dir
			if ($env:TERM_PROGRAM -eq 'vscode' -and (Get-Command code -ErrorAction SilentlyContinue)) {
				code -r $dir
			}
		}
	} else {
		& $gitExe @args
	}
}
