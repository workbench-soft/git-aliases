# A Windows setup, and both setups in the README

## Why

`install.sh` hooks into zsh, so `git sb` can't change folder in PowerShell on
Windows. The aliases already run there: Git for Windows runs each `bin/`
script in its bash.

## User flows it touches

- **Install on macOS or Linux** works as before, under its own README heading.
- **Install on Windows** a new `install.ps1` runs the same git config steps
  and adds `git sb` to the PowerShell profile.
- **Update and uninstall** the README covers both systems.

Git for Windows defaults to `core.autocrlf=true` and checks the scripts out
with CRLF endings. Bash then stops on `set -euo pipefail\r`.

## Changes

- **`.gitattributes`** added. It keeps LF endings in the checkout on each
  system.
- **`install.ps1`** added. It checks the git version and offers to remove a
  clashing `[alias]` section. It sets `gitaliases.dir` and `include.path`,
  offers to source `shell/git-sb.ps1` from `$PROFILE`, sets `core.hooksPath`
  and runs `git a`. Each change waits for a yes, and each edited file gets a
  copy first.
- **`shell/git-sb.ps1`** added. A PowerShell `git` function turns
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
