# db and dbm delete branches together with their worktrees

Done on 2025-10-16, before the history was reset to one commit. The old commits sit under `refs/backup/main` in the local backup mirror of `git-aliases`.

## Why

Deleting a branch left its worktree folder behind. The delete aliases now remove both.

## User flows it touches

- **Delete a branch** `git db` removes the branch and its worktree.
- **Dirty worktree** the alias deletes the clean ones first, then asks about the dirty ones.

## Changes

- **`bin/_lib.sh`** changed.
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
