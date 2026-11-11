# Changelog

## Unreleased

- **git a** the list stays on the screen after `q`, and a list that fits the screen prints without a pager, as `git log` does.
- **git r** `-c` fetches the remote the upstream sits on, so a fork branch that tracks the original rebases onto its newest commits. `git r <branch>` works in a `--single-branch` clone.

- **Lint before the push** `hooks/pre-push` runs `mise run lint`, so a lint or format error stays on the PC instead of failing Checks on `main`.

- **Docs** the features, flows and README describe the detached HEAD question of `git master`, the prune per remote of `git dbm`, the hook checks and the `workflow_run` release.

- **CI** Release starts on `workflow_run` once lint passes on `main`, one at a time. No job holds a runner while it waits.

- **Parallel release builds** releases build beside checks after a push. Only publication waits for matching checks; open PRs hold no build.
- **CI** the Release workflow follows the `repo-ci` template: `gh release create` makes the tag, so a failed publish leaves no stray tag. Stale comments and the agent rules pasted into the docs are gone.

- **git p, git co, git master** fetch the branch even when a tag has the same name, and git co works in a `--single-branch` clone.
- **git dbm** prunes every remote, so a branch gone from a fork remote shows up too. A remote out of reach gets a warning, and the rest go on.
- **PowerShell** the `git` function passes piped input on to git, so `Get-Content x.patch | git apply` works.
- **git sb** in PowerShell moves to a worktree folder with a non-ASCII name.
- **git p** looks up the remote once.
- **CI** the pre-commit hook runs oxfmt and markdownlint on the staged files, as CI does. The lint job pins mise and node, keeps its token out of `.git/config`, and Dependabot bumps the pinned actions.

- **CI** spec entries may repeat their Changes heading, and mise installs npm tools with npm, so oxfmt runs on Windows.
- **CI** Release waits while a PR of an agent session is open, so the last merge of a batch releases them all.
- **Docs** each heading of `docs/features.md` links its spec, and each feature that had no spec got one.
- **Markdown** markdownlint-cli2 lints the docs in `mise run lint`.

- **CI** the Windows lint job uses a fresh mise cache. The old one held an oxfmt install that failed with a missing tinypool package.
- Specs: one file per feature under `specs/`, with each dated spec moved in as an entry under `## Changes`.
- **Agent docs** `AGENTS.md` states each rule with MUST, SHOULD or MAY.
- **Architecture decisions** `docs/architecture.md` gets a Decisions section. Each big choice names its reason, its cost and the rivals it beat.

- **Format** oxfmt formats the Markdown, and CI checks it next to `lint.sh`.

- **Lint tools** the README installs shellcheck and shfmt through `mise install`, on Windows and macOS both.
- **Releases** each push to `main` that passes `lint` gets a GitHub release such as `v2026.10.30.1`. Its notes list the commits since the release before.
- **Public** the repo is open source. CI runs on GitHub runners, Linux and Windows, in place of the Windows PC. `mise.toml` pins shellcheck and shfmt.
- **Docs** `docs/user-flows.md` walks through each flow. `docs/architecture.md` says bash and shows the path of one call.
- **CI** stops a job after 20 minutes. A normal run takes about 1 minute.
- **CI** pins `actions/checkout` to the v5.1.0 commit, so a moved tag can't run new code on the Windows PC runner.
- **Lint** runs in about 7 s in place of 17 s on Windows, best of 4 runs, so the pre-commit hook waits less.
- **install.sh** in Git Bash finds its own `include.path` on a second run, and adds no copy.
- **install.sh** in Git Bash finds the aliases `~/.gitconfig` sets itself, and offers to remove them.
- **Questions** with no terminal attached, each question gets a no without the "/dev/tty: No such device or address" error.
- **git sb** in zsh and PowerShell prints what `git checkout` says, such as "Your branch is up to date".
- **git sb** leaves colour out of its menu when `NO_COLOR` is set.
- **git cb** turns a name part ending in `.lock`, which git refuses, into `-lock`: `git cb "Update yarn.lock"` makes `update-yarn-lock`.
- **git master** lists the local commits the remote lacks and asks before it drops them.
- **git master** stops before any change when another worktree holds the default branch, and names that folder.
- **Docs** `docs/features.md` and `docs/architecture.md` give a high level view with a diagram.

- **CI** runs on pushes to main only. PR runs are off, and the workflow says how to turn them back on.
- **CI** a new push to main or to a PR stops the checks and deploys still running for the commit before it.
