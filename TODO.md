# TODO

## rewrite-repo

- [ ] Decide on the palette shift for the terminal colours in `bin/_shared.sh`. The grey `38;5;240` gives about 3:1 on black, and `38;5;244` would give about 5:1.
- [ ] Machines with an old checkout: `git pull` brings `bin/_shared.sh` and `bin/_prune.sh` in place of `bin/_lib.sh`. Any local script that sources `bin/_lib.sh` needs the new names.

## app-audit

- [ ] Check the zsh `git sb` function on the Mac: pick a branch of this worktree and see "Your branch is up to date" (branch `audit-2026-10-30`). This PC has no zsh.
- [ ] Watch the first CI run on main after the merge: `actions/checkout` is now pinned to commit `fbc6f39`, and PR runs are off.
- Left: pin shellcheck and shfmt in `mise.toml` and use it in CI. Only a run on main can prove the CI change.
- Left: `git c --author "X <x>" msg` puts the author into the message. A fix changes how `git c` reads flags.
- Left: each alias takes about 0.3 s on Windows, against 0.1 s for plain git. The git alias design starts bash each time.
- Left: the palette shift above is a product call.
