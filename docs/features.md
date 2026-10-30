# Features

Short git aliases, ready for any machine.

## Aliases

- **What it gives** short commands for common git work, such as `git co`, `git cp` and `git last`.
- **Where** run `git a` to list each alias with what it does.
- **Limits** each alias starts bash, so it takes about 0.3 s on Windows.

## Reset to the default branch

- **What it gives** `git master` (also `git m`, `git main`) fetches and hard resets to the default branch of the remote.
- **Where** run it in any worktree.
- **Limits** it asks before it drops local changes or commits the remote lacks. It stops when another worktree holds the default branch.

## Switch branch folders

- **What it gives** `git sb` moves the shell into another worktree.
- **Limits** needs the shell function the installer offers, for zsh or PowerShell, and fzf.

## Delete branches and worktrees

- **What it gives** `git db` picks branches and worktrees in fzf and deletes them. `git dbm` deletes the ones whose remote branch is gone.
- **Where** the [README section](../README.md#deleting-branches-and-worktrees) lists what stays.
- **Limits** a worktree with changes gets a question first. The main worktree, the current one and locked ones stay.

## Installer

- **What it gives** sets up git config and asks before each change. A second run is safe.
- **Where** `install.sh` on macOS and Linux, `install.ps1` on Windows.
- **Limits** with no terminal, each question gets a no.
