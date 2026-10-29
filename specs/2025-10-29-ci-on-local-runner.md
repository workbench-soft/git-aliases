# CI runs on the dev machine that is on, Mac or Windows

## Why

Development moved to Windows. CI named the Mac runner, so a job waited
whenever the Mac was off.

## User flows it touches

- **Pull request** the lint job runs on the Windows PC or the Mac, on the first one online.

## Changes

- **`.github/workflows/lint.yml`** `runs-on: [self-hosted, local]`, with bash for each step. A missing shfmt or shellcheck comes from brew on the Mac and from winget on Windows.
- **`CHANGELOG.md`** one entry.

## Steps, in commit order

1. This plan and the workflow change.

## Docs to update

- `CHANGELOG.md`

## Update 2025-10-29: a new push stops the older runs

- **Why** the single local runner spent time on checks and deploys for commits a newer push had replaced.
- **Workflows** each workflow a push starts sets `cancel-in-progress: true` in a concurrency group keyed on the branch or the PR. A new push then stops the older run.
