# Releases

## What it does for the person

Each push to `main` that passes the `lint` workflow gets a GitHub release
in this repo, such as `v2026.10.30.1`. Its notes list the commits since the
release before, so a reader sees what changed without reading the log.

## User flows

1. A PR merges into `main`.
2. `lint` runs on the push and passes.
3. Release tags the commit and publishes the notes on the Releases page.

## How it works

- **`.github/workflows/release.yml`** starts on `workflow_run` once `lint.yml` passes on a
  push to `main`. One release runs at a time. It runs on `ubuntu-latest`. The repo is public, so GitHub runners cost 0 minutes and fork code stays off the PC.
- **`.github/scripts/next-version.sh`** picks the tag: the date, then the
  number of the release that day.
- **`.github/scripts/release-notes.sh`** writes the notes from the commits
  since the last tag.

## Limits

- **Notes only** the repo builds no file, so the release carries none.
- **Failed check** a red `lint` run or a PR run starts no release.
- **Matrix** the release starts only once both the Linux and the Windows job of `lint` pass.

## Changes

### 2026-10-30 a release after each passing check

- **Why** the repo had checks and shipped no release, so a merge left no
  tagged point to go back to.
- **Changes** the Release workflow and its two scripts come from the
  `repo-ci` templates. `.gitattributes` keeps LF endings on `*.sh`.
- **Steps** this spec, then the workflow and scripts, then the docs.
- **Docs** `README.md`, `CHANGELOG.md`, `docs/features.md` and `docs/architecture.md`.

### 2026-11-09 week review

- **Why** the parallel release change left stale comments, a tag pushed before its release and agent rules in the docs.
- **Changes** `release.yml` follows the `repo-ci` template, `wait-for-checks.sh` gets its run bit, and the pasted "Release build timing" sections go.
- **Docs** `README.md`, `docs/architecture.md`, `docs/user-flows.md`, `CHANGELOG.md`.

### 2026-11-10 Release starts on workflow_run

- **Why** f7cd252 moved Release from a push run that waited for lint to `workflow_run` of lint, so no job holds a runner while it waits.
- **Docs** the top of this spec and the README describe the `workflow_run` start.
