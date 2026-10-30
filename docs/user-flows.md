# User flows

## Install on a new machine

1. The person clones the repo.
2. The person runs `install.sh`, or `install.ps1` on Windows.
3. The installer asks before each change and copies each file it edits.
4. The installer runs `git a` to prove the aliases work.

```mermaid
flowchart TD
  clone["git clone"] --> run["install.sh / install.ps1"]
  run --> clash{"~/.gitconfig sets the same aliases?"}
  clash -- yes --> ask1["ask to remove its [alias] section"]
  clash -- no --> link["set gitaliases.dir and include.path"]
  ask1 --> link
  link --> shell["ask to load the git sb function"]
  shell --> hook["set core.hooksPath"]
  hook --> prove["run git a"]
```

## Look up an alias

1. The person runs `git a`.
2. The list opens in `less`, one alias per entry with its description.
3. An alias run with `-h`, or with its arguments missing, prints its usage.

```mermaid
flowchart LR
  a["git a"] --> list["each alias and its description"]
  x["git cp -h"] --> usage["usage and flags"]
```

## Commit and push

1. The person runs `git cp <message>`.
2. The alias stages all, commits, and pushes.
3. A branch with no upstream gets one on this push.

```mermaid
flowchart LR
  cp["git cp fix the parser"] --> add["git add -A"]
  add --> commit["git commit -m"]
  commit --> push{"upstream set?"}
  push -- yes --> p1["git push"]
  push -- no --> p2["git push -u origin HEAD"]
```

## Switch to a branch in another worktree

1. The person runs `git sb`.
2. fzf lists the local branches, newest first, with the folder of each worktree.
3. The person picks one.
4. A branch in this worktree gets checked out. A branch in another worktree
   moves the shell there.

```mermaid
flowchart TD
  sb["git sb"] --> menu["fzf menu"]
  menu --> pick{"branch in another worktree?"}
  pick -- no --> co["git checkout"]
  pick -- yes --> cd["shell function runs cd"]
```

## Go back to the default branch

1. The person runs `git master`.
2. The alias stops when another worktree holds the default branch.
3. It lists commits the remote lacks and local changes, with a question each.
4. It checks out the default branch and resets it to the remote.

```mermaid
flowchart TD
  m["git master"] --> held{"another worktree holds it?"}
  held -- yes --> stop["stop and name that folder"]
  held -- no --> fetch["git fetch"]
  fetch --> ahead{"local commits the remote lacks?"}
  ahead -- yes --> q1["ask"]
  ahead -- no --> dirty
  q1 -- yes --> dirty{"local changes?"}
  q1 -- no --> stop2["stop"]
  dirty -- yes --> q2["ask, then drop them"]
  dirty -- no --> reset["checkout and hard reset"]
  q2 --> reset
```

## Clean up branches and worktrees

1. The person runs `git dbm` after a PR merges, or `git db` to pick by hand.
2. The alias deletes clean worktrees and plain branches first.
3. Each worktree with changes gets a question at the end.

```mermaid
flowchart TD
  dbm["git dbm"] --> prune["git fetch --prune"]
  prune --> gone["branches whose upstream is gone"]
  db["git db"] --> fzf["fzf multi-pick"]
  gone --> del["delete clean worktrees and branches"]
  fzf --> del
  del --> ask["ask for each worktree with changes"]
```
