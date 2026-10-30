# git-aliases

Short git aliases in one repo, ready for any machine. Run `git a` to list each
alias with what it does.

Each alias is a shell script in [bin/](bin).
[aliases.gitconfig](aliases.gitconfig) maps each alias name to its script, one
line per alias.

## Install

Clone the repo to any folder and run the installer for your system. The
installer stores the folder path, so the aliases run from the clone itself.

The installers ask before each change. A file they edit first gets a copy at
`<file>.bak.<timestamp>`. Answer no to each question and only the git config
steps run. A second run is safe.

Both installers do these steps:

- **Git config** set `gitaliases.dir` and `include.path` in `~/.gitconfig`.
- **Old aliases** offer to remove an `[alias]` section from `~/.gitconfig`.
  Aliases there beat the ones from the repo.
- **`git sb`** offer to load a shell function so `git sb` can change folder.
  [The reason](#why-git-sb-needs-a-shell-function).
- **Hooks** set `core.hooksPath` to [hooks/](hooks), so each commit here runs
  the lint.
- **Check** warn when git is older than 2.22, then run `git a` to prove the
  install worked.

### macOS and Linux

```sh
git clone git@github.com:workbench-soft/git-aliases.git ~/.git-aliases && ~/.git-aliases/install.sh
```

- **Shell** `install.sh` adds a line to `~/.zshrc` that sources
  [shell/git-sb.zsh](shell/git-sb.zsh).
- **Old wrapper** when `~/.zshrc` holds its own `git()` wrapper, the installer
  prints its line number. The old block stays, and you can delete it.
- **fzf** `git sb` and `git db` need it: `brew install fzf`.

### Windows

Install [Git for Windows](https://gitforwindows.org) first:
`winget install Git.Git`. The aliases run in its bash. In PowerShell, run:

```powershell
git clone git@github.com:workbench-soft/git-aliases.git "$HOME\.git-aliases"; powershell -ExecutionPolicy Bypass -File "$HOME\.git-aliases\install.ps1"
```

- **Shell** `install.ps1` adds a line to `$PROFILE` that dot-sources
  [shell/git-sb.ps1](shell/git-sb.ps1). Windows PowerShell and PowerShell 7
  each have a profile, so run it from each one you use.
- **Execution policy** `Restricted`, the Windows default, skips `$PROFILE`.
  The installer warns about it. To allow the profile:
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- **fzf** `git sb` and `git db` need it: `winget install junegunn.fzf`.
- **Line endings** [.gitattributes](.gitattributes) keeps the scripts on LF.
  Git for Windows checks files out with CRLF by default, and bash fails on CRLF.

### Update

```sh
git -C ~/.git-aliases pull
```

PowerShell takes the same command. The installer doesn't need a second run.

## Why `git sb` needs a shell function

`git sb` can pick a branch that sits in another worktree. A git alias runs as a
child process and can't change the folder of the shell above it. So the alias
prints `__cd__ <path>`, and a shell function runs the `cd`:

- **zsh** [shell/git-sb.zsh](shell/git-sb.zsh).
- **PowerShell** [shell/git-sb.ps1](shell/git-sb.ps1).

The function also moves the VS Code window there. That needs the `code` CLI on
PATH: in the VS Code palette, run "Shell Command: Install 'code'". With
`"git.detectWorktrees": true` VS Code lists worktrees as well.

`git sb` works without the function too. It then prints the path and stays put.

## The aliases

`git a` prints this list, taken from the comments in the scripts. An alias that
needs arguments prints them when you call it with none:

```
$ git cp
usage: git cp [-f] [-p] [-s] [--] <message>

  -f  push with --force-with-lease
  -p  skip the commit and push hooks
  -s  skip staging, commit whatever is staged already
  --  makes everything after it message, even if it starts with a dash
```

`-h` prints the same text. Git adds a line about the alias above it. That line
comes from git, and the script doesn't print it.

| Alias | What it does |
| --- | --- |
| `a` | List each alias with its description |
| `b` | Print the current branch name |
| `c` | Commit, with the arguments joined into the message. Flags go to `git commit`, and `--` makes the rest message |
| `cb` | Create a branch, the name turned into lowercase-with-hyphens |
| `co` | Check out a branch, and fetch it from origin when it isn't local yet |
| `cp` | Stage all, commit, push. `-f` force-with-lease, `-p` skip hooks, `-s` skip staging, `--` makes the rest message |
| `db` | Pick branches and worktrees in fzf (TAB for several), then delete them |
| `dbm` | Prune the remotes, then offer to delete branches and worktrees whose upstream is gone |
| `hr` | Hard reset to HEAD and delete untracked files |
| `last` | Show the last commit with its diff |
| `m`, `main`, `master` | Drop local changes and unpushed commits (after a question), fetch, hard reset to the default branch |
| `p` | Pull with rebase from the remote branch of the same name |
| `r` | Fetch and rebase onto the default branch. `-c` uses the upstream, or pass a branch |
| `sb` | Pick a local branch in fzf and switch to it, worktrees included |
| `sr1` | Undo the last commit, and keep its changes staged |
| `srmb` | Soft reset to the merge base with the default branch, and keep the changes staged |

### Deleting branches and worktrees

`db` and `dbm` label each entry `[branch]` or `[worktree]`. A worktree entry
shows its folder. `db` also offers detached worktrees, which have no branch.
`dbm` lists only branches whose upstream was deleted.

- **Cleanup** git deletes the worktree folder and its metadata, then the
  branch. The branch takes its reflog and config with it. A dev server that
  writes into the folder can leave the folder behind. The alias then deletes
  it, or warns with the ids of the processes that hold it.
- **Questions** the alias first deletes each entry git allows without
  `--force`. At the end it asks once per worktree git refused. Yes retries with
  `--force` and loses uncommitted changes and untracked or ignored files. No
  keeps that worktree and its branch.
- **Failures** a failed entry prints a warning, and the rest still go. The
  alias then exits with 1.
- **Protected** the main worktree, the current one and locked ones stay, and
  their branches too. A worktree whose folder holds another worktree stays. A
  branch stays while another worktree has it checked out.
- **Shared data** the stash, remote branches and git objects stay in the repo.
  Git's garbage collection deals with unreachable objects. Outside caches and
  editor sessions stay as they are.

`dbm` took over from the old `dwm` alias.

The remote is `origin`, or the single remote when it has another name. The
default branch comes from `<remote>/HEAD`, then `master`, then `main`. When
`<remote>/HEAD` is missing, run `git remote set-head origin --auto`.

## Adding or changing an alias

1. Write `bin/git-<name>`: `#!/usr/bin/env bash`, then a `# ` comment on what
   it does, then `set -euo pipefail`.
2. Source `bin/_shared.sh` for the helpers: `trace_run` (print a command, then
   run it), `trace`, `ask_yes`, `abort`, `need_command`, `pick_remote`,
   `remote_head_branch`. The delete aliases also source `bin/_prune.sh`.
3. Run `chmod +x bin/git-<name>`. On Windows:
   `git update-index --add --chmod=+x bin/git-<name>`.
4. Add a line to `aliases.gitconfig`, in sorted order.
5. Add a row to the table above.
6. Add a check to `test.sh` when the alias does something worth pinning down.

## Checks

```sh
./lint.sh   # shape: comments, alias lines, README rows, shell style
./test.sh   # behaviour: every alias against a throwaway repo
```

On Windows, run both from Git Bash.

`lint.sh` fails when a script:

- **Comment** has no description comment on line 2.
- **Shape** isn't executable or lacks `set -euo pipefail`.
- **Links** has no alias, or its alias has no README row.
- **Alias lines** drift from their fixed shape.

NTFS has no exec bit, so on Windows `lint.sh` reads the mode git stored.

With [shellcheck](https://www.shellcheck.net) and
[shfmt](https://github.com/mvdan/sh) installed, `lint.sh` runs them too. With
PowerShell installed, it parses the `.ps1` files. To install the tools and fix
the formatting:

```sh
brew install shellcheck shfmt
shfmt --write --case-indent bin/* ./*.sh hooks/*
```

`test.sh` builds a repo and a `HOME` in a temp folder. It commits, pushes and
resets for real there, and your own files stay untouched. On Windows it skips
the folder name with a tab and a newline, since NTFS rejects it.

`install.sh` sets `core.hooksPath` to [hooks/](hooks), so the lint runs before
each commit. GitHub Actions runs both checks on each push to main.

## Uninstall

```sh
git config --global --unset gitaliases.dir
git config --global --unset include.path 'git-aliases.*/aliases\.gitconfig$'
```

PowerShell takes the same commands. Then:

1. Remove the line that loads `git-sb.zsh` from `~/.zshrc`, or `git-sb.ps1`
   from `$PROFILE`.
2. Delete the clone.

## License

[MIT](LICENSE).
