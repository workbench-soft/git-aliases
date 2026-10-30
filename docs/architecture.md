# Architecture

Each alias is a shell script in `bin/`. Git finds them through an include in `~/.gitconfig`.

```mermaid
flowchart LR
  user["git co"] --> gitconfig["~/.gitconfig<br/>include.path"]
  gitconfig --> aliases["aliases.gitconfig"]
  aliases --> bin["bin/git-co<br/>shell script"]
  bin --> shared["bin/_shared.sh"]
  install["install.sh / install.ps1"] --> gitconfig
  install --> shell["shell/git-sb.zsh, git-sb.ps1"]
```

| Part | Technology | Job |
| --- | --- | --- |
| Aliases | POSIX shell | The commands |
| Map | `aliases.gitconfig` | Alias name to script |
| Installer | Shell, PowerShell | Wires up `~/.gitconfig` |
| Checks | `lint.sh`, `test.sh`, pre-commit hook | Keep the scripts working |
