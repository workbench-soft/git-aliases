# Hooks this checkout into the global git config on Windows, the way install.sh
# does on macOS and Linux. A rerun is safe: each change waits for a yes, each
# edited file gets a copy first, and $PROFILE only grows.
$ErrorActionPreference = 'Stop'

# The bin/ scripts run in the bash of Git for Windows, and git config wants
# forward slashes.
$repo = $PSScriptRoot -replace '\\', '/'
$index = "$repo/aliases.gitconfig"
# Git reads HOME when it is set, and the user profile folder when it isn't.
$gitHome = if ($env:HOME) { $env:HOME } else { $HOME }
$userGitconfig = Join-Path $gitHome '.gitconfig'
$profileFile = $PROFILE.CurrentUserCurrentHost
$profileLine = ". `"$PSScriptRoot\shell\git-sb.ps1`""

# Without a console (a pipe, CI) every question gets a no.
function Confirm-Step([string]$Question) {
	if ([Console]::IsInputRedirected) { return $false }
	$reply = Read-Host "$Question [y/N]"
	return $reply -match '^(y|yes)$'
}

function Save-Copy([string]$File) {
	if (-not (Test-Path -LiteralPath $File)) { return }
	$copy = "$File.bak.$(Get-Date -Format yyyyMMddHHmmss)"
	Copy-Item -LiteralPath $File -Destination $copy
	Write-Host "  backup: $copy"
}

# git b and git p rely on `git branch --show-current`, added in git 2.22.
function Test-GitVersion {
	if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
		Write-Error 'git is not on PATH. Install Git for Windows: winget install Git.Git'
	}
	if ((git version) -match '(\d+)\.(\d+)') {
		$found = [version]"$($Matches[1]).$($Matches[2])"
		if ($found -lt [version]'2.22') {
			Write-Host "warning: git $found is old, git b and git p need 2.22 for --show-current"
			Write-Host
		}
	}
}

# An alias set in ~/.gitconfig itself beats the same alias from an include.
function Remove-ClashingAliases {
	$ours = @(git config --file $index --name-only --get-regexp '^alias\.') -replace '^alias\.', ''
	$theirs = @(git config --global --name-only --get-regexp '^alias\.') -replace '^alias\.', ''
	$clashes = @($ours | Where-Object { $theirs -contains $_ } | Sort-Object -Unique)
	if ($clashes.Count -eq 0) { return }

	Write-Host 'Your ~/.gitconfig defines these aliases itself, so they would shadow the repo:'
	foreach ($name in $clashes) { Write-Host "  $name" }
	if (Confirm-Step 'Remove the [alias] section from ~/.gitconfig?') {
		Save-Copy $userGitconfig
		git config --global --remove-section alias
		Write-Host '  removed'
	} else {
		Write-Host '  left as is, so the repo aliases stay shadowed'
	}
	Write-Host
}

function Add-AliasInclude {
	git config --global gitaliases.dir $repo
	Write-Host "gitaliases.dir = $repo"
	if (@(git config --global --get-all include.path) -contains $index) {
		Write-Host "include.path already has $index"
	} else {
		git config --global --add include.path $index
		Write-Host "include.path += $index"
	}
	Write-Host
}

# git sb prints "__cd__ <path>", and the PowerShell function turns it into a cd.
function Add-ProfileWrapper {
	$profileText = ''
	if (Test-Path -LiteralPath $profileFile) {
		$profileText = Get-Content -LiteralPath $profileFile -Raw
	}
	if ($profileText -like '*shell\git-sb.ps1*') {
		Write-Host 'PowerShell: $PROFILE already sources shell\git-sb.ps1'
	} elseif (Confirm-Step "PowerShell: let git sb change directory by sourcing it from $profileFile?") {
		Save-Copy $profileFile
		New-Item -ItemType Directory -Force -Path (Split-Path $profileFile) | Out-Null
		Add-Content -LiteralPath $profileFile -Value "`n# git-aliases`n$profileLine"
		Write-Host '  added, pick it up with: . $PROFILE'
	} else {
		Write-Host "PowerShell: skipped, add this to `$PROFILE yourself: $profileLine"
	}

	# Restricted, the Windows default, and AllSigned both skip an unsigned $PROFILE.
	$policy = Get-ExecutionPolicy
	if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
		Write-Host "note: execution policy is $policy, so PowerShell won't load `$PROFILE."
		Write-Host '      To allow it: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
	}
}

function Test-Install {
	git -C $repo a *> $null
	if ($LASTEXITCODE -eq 0) {
		Write-Host 'Done. Run: git a'
	} else {
		Write-Error 'Something is off: git a does not run. Check include.path in ~/.gitconfig.'
	}
}

Write-Host "Installing from $repo"
Write-Host
Test-GitVersion
Remove-ClashingAliases
Add-AliasInclude
Add-ProfileWrapper
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
	Write-Host 'note: git sb and git db need fzf: winget install junegunn.fzf'
}
Write-Host
git -C $repo config core.hooksPath hooks
Test-Install
