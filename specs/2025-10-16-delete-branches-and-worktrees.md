# db and dbm remove a branch and its worktree together

Finished on 2025-10-16, before the history reset to one commit. The local backup mirror of `git-aliases` keeps the old commits under `refs/backup/main`.

## Why

A deleted branch used to leave its worktree folder on disk. The delete aliases now remove the branch and the folder.

## User flows it touches

- **Delete a branch** `git db` removes the branch and its worktree.
- **Worktree with changes** the alias removes the clean entries first, then asks about each one with changes.

## Changes

- **`bin/_lib.sh`** changed. Its delete code now sits in `bin/_prune.sh`.
- **`test.sh`** changed.
- **`aliases.gitconfig`** changed.
- **`bin/git-db`** changed.
- **`bin/git-dbm`** changed.
- **`bin/git-dwm`** removed.

## Steps, in commit order

1. Delete branches and worktrees together with db and dbm (df25a8a, 2025-10-16)
2. Finish deleting a worktree when a dev server writes into it (4bc3c52, 2025-10-16)
3. Skip the force prompt when git already removed a clean worktree (3e8b044, 2025-10-16)
4. Ask about dirty worktrees after deleting the rest (56b1698, 2025-10-16)

## Docs to update

- `AGENTS.md`
- `README.md`
