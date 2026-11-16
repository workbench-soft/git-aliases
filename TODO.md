# TODO

## rewrite-repo

- [ ] Machines with an old checkout: `git pull` brings `bin/_shared.sh` and `bin/_prune.sh` in place of `bin/_lib.sh`. Any local script that sources `bin/_lib.sh` needs the new names.

## app-audit

- [ ] Check the zsh `git sb` function on the Mac: pick a branch of this worktree and see "Your branch is up to date" (PR #9). This PC has no zsh.
- Left: `git c --author "X <x>" msg` puts the author into the message. A fix changes how `git c` reads flags.
- Left: each alias takes about 0.3 s on Windows, against 0.1 s for plain git. The git alias design starts bash each time.
- Left: the fzf preview shows the history of a tag named like the branch. Display only, and the fix needs shell syntax fzf may run in cmd.exe.
- Left: markdownlint-cli2 0.24.0 has npm audit highs (re2js, katex). Dev only, and the fix is a downgrade.
- Left: old commits carry a personal email in a public repo. Removing it needs a history rewrite.
- Left: oxfmt 0.76.0 is out. A 0.x bump can reformat files, so it goes in its own change.
- Left: no test for the zsh `__cd__` reader or for install.ps1, and test.sh is one 550 line file. Effort M each.
- Left: fetch, pull and push in the aliases have no timeout. Every alias fetches before it changes anything, so Ctrl+C is safe.
- Left: `git a | head` on Windows prints an awk "print to standard output failed" line once head closes the pipe. Display only.
- Left: `git srmb` reads the last fetched default branch. A fetch would add a network call to a local reset.
- Left: the commit hook checks the working copy of each staged file, so an unstaged edit in a staged file can still block the commit. The fix needs a temp index or a checkout of the staged blobs.
