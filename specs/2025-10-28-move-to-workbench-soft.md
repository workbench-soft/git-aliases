# Move git-aliases to workbench-soft and make it private

## Why

The repo moved from `oleg-chibikov` to the `workbench-soft` org and is private now.
GitHub's runners bill minutes on a private repo, and the README clones the old address.

## User flows it touches

- **Install** the clone line names `workbench-soft/git-aliases`.

## Changes

- **`.github/workflows/lint.yml`** runs on the Mac runner and gets `shfmt` from Homebrew.
- **`README.md`** the clone line names the new owner.
- **`CHANGELOG.md`** new, with one entry.

## Steps, in commit order

1. Move CI to the Mac.
2. Point the README at the new owner.

## Docs to update

- `README.md` install.
