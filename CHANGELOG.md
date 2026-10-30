# Changelog

## Unreleased

- **CI** pins `actions/checkout` to the v5.1.0 commit, so a moved tag can't run new code on the Windows PC runner.
- **Lint** runs in about 7 s in place of 17 s on Windows, best of 4 runs, so the pre-commit hook waits less.
- **install.sh** in Git Bash finds its own `include.path` on a second run, and adds no copy.
- **install.sh** in Git Bash finds the aliases `~/.gitconfig` sets itself, and offers to remove them.
- **Questions** with no terminal attached, each question gets a no without the "/dev/tty: No such device or address" error.
- **git sb** in zsh and PowerShell prints what `git checkout` says, such as "Your branch is up to date".
- **git sb** leaves colour out of its menu when `NO_COLOR` is set.
- **git cb** turns a name part ending in `.lock`, which git refuses, into `-lock`: `git cb "Update yarn.lock"` makes `update-yarn-lock`.
- **git master** lists the local commits the remote lacks and asks before it drops them.
- **git master** stops before any change when another worktree holds the default branch, and names that folder.
- **Docs** `docs/features.md` and `docs/architecture.md` give a high level view with a diagram.

- **CI** runs on pushes to main only. PR runs are off, and the workflow says how to turn them back on.
- **CI** a new push to main or to a PR stops the checks and deploys still running for the commit before it.
