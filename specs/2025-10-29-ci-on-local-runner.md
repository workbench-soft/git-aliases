# Run CI on whichever dev machine is on, Mac or Windows

## Why

Development moved to Windows. CI asked for the Mac runner by name and waited while the Mac was off.

## User flows it touches

- **Pull request** the lint job runs on the Windows PC or the Mac, whichever is online.

## Changes

- **`.github/workflows/lint.yml`** `runs-on: [self-hosted, local]`, steps run in bash. A missing shfmt or shellcheck installs through brew on the Mac and winget on Windows.
- **`CHANGELOG.md`** one entry.

## Steps, in commit order

1. This plan and the workflow change.

## Docs to update

- `CHANGELOG.md`
