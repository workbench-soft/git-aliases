# TODO

## rewrite-repo

- [ ] Fix `git sb` colouring its menu while `NO_COLOR` is set: the awk in `bin/git-sb` hard codes `\033[38;5;240m`. Pass `CLR_FAINT` and `CLR_OFF` in.
- [ ] Fix the `git sb` wrappers in `shell/git-sb.zsh` and `shell/git-sb.ps1` dropping stdout from `git sb` when no `__cd__` line comes, such as "Your branch is up to date".
- [ ] Fix `install.sh` missing alias clashes in Git Bash: `--show-origin` prints `file:C:/...` and the script compares with `/c/...`. Read `~/.gitconfig` with `git config --file` in `install.sh` and `install.ps1`.
- [ ] Fix `ask_yes` in `bin/_shared.sh` and `install.sh` printing "/dev/tty: No such device or address" when no terminal is attached.
- [ ] Decide on the palette shift for the terminal colours in `bin/_shared.sh`. The grey `38;5;240` gives about 3:1 on black, and `38;5;244` would give about 5:1.
- [ ] Machines with an old checkout: `git pull` brings `bin/_shared.sh` and `bin/_prune.sh` in place of `bin/_lib.sh`. Any local script that sources `bin/_lib.sh` needs the new names.
