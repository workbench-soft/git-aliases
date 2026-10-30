# Changelog

## Unreleased

- **Docs** `docs/features.md` and `docs/architecture.md` give a high level view with a diagram.

- **CI** runs on pushes to main only. PR runs are off, and the workflow says how to turn them back on.
- **CI** a new push to main or to a PR stops the checks and deploys still running for the commit before it.
