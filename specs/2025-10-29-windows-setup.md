# Add a Windows setup and describe both in the README

## Why

`install.sh` wires up zsh, so on Windows `git sb` can't change directory in
PowerShell. The aliases themselves run on Windows already: Git for Windows
runs each `bin/` script with its own bash.

## User flows it touches

- **Install on macOS or Linux** stays as it is, the README moves it under its
  own heading.
- **Install on Windows** a new `install.ps1` does the same git config steps and
  hooks `git sb` into the PowerShell profile.
- **Update and uninstall** the README covers both systems.

With `core.autocrlf=true`, the Git for Windows default, git checks the scripts
out with CRLF line endings. Bash then fails on `set -euo pipefail\r`.

## Changes

- **`.gitattributes`** new. Keeps LF line endings in the checkout on every
  system.
- **`install.ps1`** new. Checks the git version, offers to drop a clashing
  `[alias]` section, sets `gitaliases.dir` and `include.path`, offers to
  source `shell/git-sb.ps1` from `$PROFILE`, sets `core.hooksPath`, runs
  `git a`. Asks before every change and backs up each file it edits.
- **`shell/git-sb.ps1`** new. A PowerShell `git` function that turns
  `__cd__ <path>` into `Set-Location`, then moves the VS Code window.
- **`lint.sh`** parses the `.ps1` files when `pwsh` is installed.
- **`README.md`** install, update and uninstall split into macOS and Linux,
  then Windows.
- **`CHANGELOG.md`** one entry.

## Steps, in commit order

1. This plan.
2. `.gitattributes`.
3. `shell/git-sb.ps1`, `install.ps1` and the lint check.
4. README and changelog.

## Docs to update

- `README.md` install, `git sb`, checks, uninstall.
- `CHANGELOG.md`.
