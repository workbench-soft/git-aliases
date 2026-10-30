# Changelog

## Unreleased

- **git sb** leaves colour out of its menu when `NO_COLOR` is set.
- **git cb** turns a name part ending in `.lock`, which git refuses, into `-lock`: `git cb "Update yarn.lock"` makes `update-yarn-lock`.
- **git master** lists the local commits the remote lacks and asks before it drops them.
- **git master** stops before any change when another worktree holds the default branch, and names that folder.
- **Docs** `docs/features.md` and `docs/architecture.md` give a high level view with a diagram.

- **CI** runs on pushes to main only. PR runs are off, and the workflow says how to turn them back on.
- **CI** a new push to main or to a PR stops the checks and deploys still running for the commit before it.
