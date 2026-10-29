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

## Update 2026-10-29: a newer push cancels the older runs

- **Why** the one local runner spent its time on checks and deploys of commits a newer push already replaced.
- **Workflows** each workflow a push starts sets `cancel-in-progress: true` in its concurrency group, keyed on the branch or the PR, so a newer push stops the older run.
