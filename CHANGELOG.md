# Changelog

## Unreleased

- Spec dates for 2026 moved back one year, to 2025.

- **CI** runs on whichever dev machine is on, the Mac or the Windows PC.

- **Moved** the repo is private in `workbench-soft` now. The install clones from the new owner. CI runs on the Mac runner.
- **Windows** `install.ps1` sets up the aliases from PowerShell, and `shell/git-sb.ps1` lets `git sb` change directory there. `.gitattributes` keeps the scripts on LF, so bash runs them. `lint.sh` and `test.sh` pass in Git Bash.
