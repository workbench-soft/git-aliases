# db and dbm remove a branch and its worktree together

## What it does for the person

A deleted branch used to leave its worktree folder on disk. The delete aliases now remove the branch and the folder.

## User flows

- **Delete a branch** `git db` removes the branch and its worktree.
- **Worktree with changes** the alias removes the clean entries first, then asks about each one with changes.

## How it works: modules, files, data

Each entry below names the files it changed.

## Limits

None written down yet.

## Changes

### 2025-10-16 db and dbm remove a branch and its worktree together

Finished on 2025-10-16, before the history reset to one commit. The local backup mirror of `git-aliases` keeps the old commits under `refs/backup/main`.

#### Why

A deleted branch used to leave its worktree folder on disk. The delete aliases now remove the branch and the folder.

#### User flows it touches

- **Delete a branch** `git db` removes the branch and its worktree.
- **Worktree with changes** the alias removes the clean entries first, then asks about each one with changes.

#### Changes

- **`bin/_lib.sh`** changed. Its delete code now sits in `bin/_prune.sh`.
- **`test.sh`** changed.
- **`aliases.gitconfig`** changed.
- **`bin/git-db`** changed.
- **`bin/git-dbm`** changed.
- **`bin/git-dwm`** removed.

#### Steps, in commit order

1. Delete branches and worktrees together with db and dbm (df25a8a, 2025-10-16)
2. Finish deleting a worktree when a dev server writes into it (4bc3c52, 2025-10-16)
3. Skip the force prompt when git already removed a clean worktree (3e8b044, 2025-10-16)
4. Ask about dirty worktrees after deleting the rest (56b1698, 2025-10-16)

#### Docs to update

- `AGENTS.md`
- `README.md`

### 2026-11-10 `git dbm` prunes each remote

- **Why** the 2026-11-03 audit made `git dbm` prune every remote, so a branch that tracks a second remote counts too. The docs still showed `git fetch --all --prune`.
- **Changes** `bin/git-dbm` runs `git fetch --prune <remote>` per remote. A remote out of reach keeps only its own gone branches, with a warning.
- **Docs** `docs/features.md` and `docs/user-flows.md`.

## 2026-11-17 Unpushed work and one call

- **Why** 50 branches took 14.5 s one by one, and `-D` dropped commits that
  sat on no remote without a word. The person picked both changes.
- **Picked** `keep_unpushed` in `bin/_prune.sh` counts commits ahead of the
  upstream, or on no remote when the branch never had one, and asks once. A
  gone upstream counts as pushed, since a merged PR deletes its branch. Plain
  branches then go in one `git branch -D`. Git deletes the rest when one fails,
  so the alias names each branch still there or unknown to git.
