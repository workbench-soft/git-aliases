# Short git aliases, an installer and tests

Finished on 2025-09-16, before the history reset to one commit. The local backup mirror of `git-aliases` keeps the old commits under `refs/backup/main`.

## Why

Everyday git commands needed too much typing. Short aliases replace them, and a single command sets them up on a new machine.

## User flows it touches

- **Install** a single command asks first, copies each file it edits, then sets up the aliases.
- **List** `git a` prints each alias.
- **Wrong call** an alias run without its arguments prints what it needs.

## Changes

- **`bin/_lib.sh`** added. Later split into `bin/_shared.sh` and `bin/_prune.sh`.
- **`bin/git-cp`** added.
- **`.github/workflows/lint.yml`** added.
- **`bin/git-c`** added.
- **`bin/git-co`** added.
- **`bin/git-r`** added.
- **`install.sh`** added.
- **`lint.sh`** added.
- **`test.sh`** added.
- **`aliases.gitconfig`** added.
- **Other files** 17 more.

## Steps, in commit order

1. Add git aliases and README (af8ba5b, 2025-09-16)
2. Move aliases into shell scripts, add lint and installer (44fc648, 2025-09-16)
3. Say up front that git a lists the aliases (14cc0e9, 2025-09-16)
4. Install the git sb wrapper and cut the install to one command (826995c, 2025-09-16)
5. Make the installer ask first and keep a backup of every file it edits (12e7ba7, 2025-09-16)
6. Add behaviour tests and a license (ccec3e1, 2025-09-16)
7. Stop assuming the remote is called origin (f595c9e, 2025-09-16)
8. Let a commit message start with a dash, add editorconfig (390b9db, 2025-09-16)
9. Show the arguments when an alias is called without them (fb242a9, 2025-09-16)

## Docs to update

- `README.md`

## 2025-10-30 git master asks before it drops commits

- **Why** `git master` reset the default branch to the remote and lost the
  local commits the remote lacked, with no question. In a linked worktree it
  dropped the local changes first, then failed: another worktree held the
  default branch.
- **Changes** `bin/git-master` stops before any change when another worktree
  holds the default branch, and names that folder. It lists the commits the
  remote lacks and asks before the reset. `test.sh` checks both.
- **Steps** 1. this entry. 2. stop early when another worktree holds the
  branch. 3. ask before dropping commits.
- **Docs** the `master` row in `README.md`, `CHANGELOG.md`.
