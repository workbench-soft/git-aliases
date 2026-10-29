# git-aliases moves to workbench-soft as a private repo

## Why

The repo left `oleg-chibikov` for the `workbench-soft` org and became private.
GitHub bills hosted runner minutes on a private repo, and the README still
cloned the old address.

## User flows it touches

- **Install** the clone line points at `workbench-soft/git-aliases`.

## Changes

- **`.github/workflows/lint.yml`** runs on the Mac runner, with `shfmt` from Homebrew.
- **`README.md`** the clone line names the new owner.
- **`CHANGELOG.md`** added, with one entry.

## Steps, in commit order

1. Move CI to the Mac.
2. Point the README at the new owner.

## Docs to update

- `README.md` install.
