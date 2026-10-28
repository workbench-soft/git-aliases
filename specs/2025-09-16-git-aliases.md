# Short git aliases with an installer and tests

Done on 2025-09-16, before the history was reset to one commit. The old commits sit under `refs/backup/main` in the local backup mirror of `git-aliases`.

## Why

Everyday git commands took too much typing. Short aliases cover them, and one command installs them on a new machine.

## User flows it touches

- **Install** one command asks first, backs up each file it edits, then installs the aliases.
- **List** `git a` lists every alias.
- **Wrong call** an alias called without its arguments shows what it needs.

## Changes

- **`bin/_lib.sh`** new.
- **`bin/git-cp`** new.
- **`.github/workflows/lint.yml`** new.
- **`bin/git-c`** new.
- **`bin/git-co`** new.
- **`bin/git-r`** new.
- **`install.sh`** new.
- **`lint.sh`** new.
- **`test.sh`** new.
- **`aliases.gitconfig`** new.
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
