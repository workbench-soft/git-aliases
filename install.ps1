# Wires this checkout into the global git config on Windows. Safe to run again:
# it asks before every change, copies any file it edits first, and only ever
# appends. install.sh does the same for macOS and Linux.
$ErrorActionPreference = 'Stop'

# Git config takes forward slashes, and the bin/ scripts run in Git's bash.
$root = $PSScriptRoot -replace '\\', '/'
$config = "$root/aliases.gitconfig"
# Git reads HOME when it is set, and the user profile folder otherwise.
$gitHome = if ($env:HOME) { $env:HOME } else { $HOME }
$gitconfig = Join-Path $gitHome '.gitconfig'
$profilePath = $PROFILE.CurrentUserCurrentHost
$sourceLine = ". `"$PSScriptRoot\shell\git-sb.ps1`""

# No console (piped, CI) means no changes that need a decision.
function Ask([string]$question) {
	if ([Console]::IsInputRedirected) { return $false }
	$answer = Read-Host "$question [y/N]"
	return $answer -match '^(y|yes)$'
}

function Backup([string]$file) {
	if (-not (Test-Path -LiteralPath $file)) { return }
	$copy = "$file.bak.$(Get-Date -Format yyyyMMddHHmmss)"
	Copy-Item -LiteralPath $file -Destination $copy
	Write-Host "  backup: $copy"
}

Write-Host "Installing from $root"
Write-Host

# --- git version ------------------------------------------------------------

if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
	Write-Error 'git is not on PATH. Install Git for Windows: winget install Git.Git'
}
if ((git version) -match '(\d+)\.(\d+)') {
	$version = [version]"$($Matches[1]).$($Matches[2])"
	if ($version -lt [version]'2.22') {
		Write-Host "warning: git $version is old, git b and git p need 2.22 for --show-current"
		Write-Host
	}
}

# --- the aliases themselves -------------------------------------------------

# Aliases written straight into ~/.gitconfig win over included ones, so sort
# that out before wiring the include up.
$own = @(git config --file $config --name-only --get-regexp '^alias\.') -replace '^alias\.', ''
$existing = @(git config --global --name-only --get-regexp '^alias\.') -replace '^alias\.', ''
$clashing = @($own | Where-Object { $existing -contains $_ } | Sort-Object -Unique)

if ($clashing.Count -gt 0) {
	Write-Host 'Your ~/.gitconfig defines these aliases itself, so they would shadow the repo:'
	$clashing | ForEach-Object { Write-Host "  $_" }
	if (Ask 'Remove the [alias] section from ~/.gitconfig?') {
		Backup $gitconfig
		git config --global --remove-section alias
		Write-Host '  removed'
	} else {
		Write-Host '  left as is, so the repo aliases stay shadowed'
	}
	Write-Host
}

git config --global gitaliases.dir $root
Write-Host "gitaliases.dir = $root"

if (@(git config --global --get-all include.path) -contains $config) {
	Write-Host "include.path already has $config"
} else {
	git config --global --add include.path $config
	Write-Host "include.path += $config"
}
Write-Host

# --- the PowerShell side of git sb ------------------------------------------

# git sb prints "__cd__ <path>" and the wrapper turns that into a real cd.
$profileText = ''
if (Test-Path -LiteralPath $profilePath) {
	$profileText = Get-Content -LiteralPath $profilePath -Raw
}

if ($profileText -like '*shell\git-sb.ps1*') {
	Write-Host 'PowerShell: $PROFILE already sources shell\git-sb.ps1'
} elseif (Ask "PowerShell: let git sb change directory by sourcing it from $profilePath?") {
	Backup $profilePath
	New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null
	Add-Content -LiteralPath $profilePath -Value "`n# git-aliases`n$sourceLine"
	Write-Host '  added, pick it up with: . $PROFILE'
} else {
	Write-Host "PowerShell: skipped, add this to `$PROFILE yourself: $sourceLine"
}

# The default Windows policy, Restricted, skips $PROFILE.
$policy = Get-ExecutionPolicy
if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
	Write-Host "note: execution policy is $policy, so PowerShell won't load `$PROFILE."
	Write-Host '      To allow it: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
}

if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
	Write-Host 'note: git sb and git db need fzf: winget install junegunn.fzf'
}
Write-Host

# --- check it worked --------------------------------------------------------

git -C $root config core.hooksPath hooks

git -C $root a *> $null
if ($LASTEXITCODE -eq 0) {
	Write-Host 'Done. Run: git a'
} else {
	Write-Error 'Something is off: git a does not run. Check include.path in ~/.gitconfig.'
}
