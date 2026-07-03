# Windows (LORE and future Windows/WSL machines)

Windows machines run this repo *twice*:

1. **Inside WSL Ubuntu** — the normal Home Manager flake (`homeConfigurations.james`)
   manages the Linux user environment. `~/.config/nix` in WSL is a symlink to the
   canonical checkout on the Windows Dev Drive (`/mnt/r/Git.Local/KofTwentyTwo/nix`),
   so `switch` (the zsh helper) and all `~/.config/nix` docs work unchanged.
2. **On the Windows side** — this `windows/` folder manages native dev tooling
   with winget + scoop, applied by `apply.ps1` (the Windows analog of `switch`).

## Apply

```powershell
R:\Git.Local\KofTwentyTwo\nix\windows\apply.ps1                # install missing
R:\Git.Local\KofTwentyTwo\nix\windows\apply.ps1 -Upgrade      # + upgrade existing
R:\Git.Local\KofTwentyTwo\nix\windows\apply.ps1 -SkipVS       # skip Visual Studio
R:\Git.Local\KofTwentyTwo\nix\windows\apply.ps1 -VSEdition Professional
```

Idempotent — installed packages are skipped; edit a manifest and re-run.

## What manages what

| Layer | Tool | Manifest | Examples |
|-------|------|----------|----------|
| GUI / heavy apps | winget | `winget.json` | JetBrains Toolbox, Node LTS, Visual Studio 2026 |
| CLI tools | scoop | `scoop.json` | bat, eza, fd, ripgrep, gh, git-crypt, temurin JDK |
| JetBrains IDEs | **Toolbox** (not winget) | — | IDEA, GoLand, CLion, DataGrip, ... installs/updates/licenses live in the Toolbox app |
| VS workloads | VS Installer | `vs2026.vsconfig` | ManagedDesktop, NetWeb, NativeDesktop |
| Nerd fonts | scoop `nerd-fonts` bucket | ad hoc | deliberately not pinned (the full set is installed on LORE) |
| WSL user env | Home Manager | `../flake.nix#james` | zsh, nvim, git, tmux, CLI parity via `home/linux-cli` |

## Visual Studio 2026

- Edition default lives in `winget.json` (`visualStudio.edition`); override per run
  with `-VSEdition`. Editions map to winget IDs `Microsoft.VisualStudio.<edition>`
  (the 2026/18.x line dropped the year from the ID).
- Workloads/components are declared in `vs2026.vsconfig`. On first install the
  config is passed to the installer; on later runs `apply.ps1` re-applies it via
  `setup.exe modify`, so manifest edits converge existing installs.

## The canonical checkout (git-crypt + line endings)

The repo at `R:\Git.Local\KofTwentyTwo\nix` is shared between Windows git and WSL
git through the `/mnt/r` drvfs mount. Two invariants keep that healthy:

- **`core.autocrlf=false`** (repo-local) and an all-LF working tree. Never let a
  Windows clone smudge CRLF into the tree — Home Manager deploys these files as
  shell scripts inside WSL.
- **git-crypt on both sides**: WSL uses the nix-profile binary; Windows uses the
  scoop `git-crypt` shim. `.git/config` filter entries are PATH-relative
  (`"git-crypt" smudge/clean`) so each OS resolves its own binary. If a fresh
  clone is ever needed: clone on Windows, `git config core.autocrlf false`,
  checkout LF, then `git-crypt unlock` (key via GPG or exported symmetric key).

WSL mounts `R:` via `/etc/fstab` (`R: /mnt/r drvfs rw,noatime,uid=1000,gid=1000,...`)
because Dev Drive VHDXs attach after WSL's automount pass.
