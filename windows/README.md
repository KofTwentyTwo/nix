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

## PowerShell aliases (zsh parity)

`profile.ps1` (dot-sourced from `$PROFILE` by `apply.ps1`) also loads
`ps-aliases.ps1`, which mirrors the zsh alias set as PowerShell functions: the
full oh-my-zsh `git`/`kubectl`/`docker`/`helm`/`terraform` alias families plus
`home/zsh` shellAliases. So `gst`, `gco`, `gcb`, `gp`, `gl`, `gcm`, `gpsup`,
`glo`, `k`, `tf`, etc. work identically in PowerShell and zsh.

Notes:
- Colliding PowerShell built-in aliases (`gp`=Get-ItemProperty, `gl`=Get-Location,
  `gc`=Get-Content, `gm`=Get-Member, `gi`=Get-Item, `gcm`=Get-Command, …) are
  removed so the git functions win — the cmdlets stay available by full name.
- PowerShell is case-insensitive, so case-only omz variants (`gcB`, `gbD`) are
  not distinct — use the git flag directly.
- Branch-helper aliases (`gcm`, `gswm`, `gpsup`, …) use `Get-GitMainBranch` /
  `Get-GitCurrentBranch` / `Get-GitDevelopBranch` helpers.
- Multi-repo helper scripts (`gsa`, `gclo`, `gba`, `gi`, …) run the bash script
  in WSL at the translated current directory.
- Modern-CLI shortcuts (`cat`→bat, `ll`→eza, `grep`→rg, …) activate only if the
  tool is on PATH.

**Regenerate** after `nix flake update` bumps oh-my-zsh, or after editing
`home/ohmyzsh` plugins / `home/zsh` shellAliases:

```powershell
pwsh -File R:\Git.Local\KofTwentyTwo\nix\windows\gen-ps-aliases.ps1
```

It copies the enabled plugin files from the WSL nix store, regenerates
`ps-aliases.ps1`, and refuses to write output that doesn't parse. Commit the
result.

## What manages what

| Layer | Tool | Manifest | Examples |
|-------|------|----------|----------|
| GUI / heavy apps | winget | `winget.json` | JetBrains Toolbox, Node LTS, Visual Studio 2026 |
| CLI tools | scoop | `scoop.json` | bat, eza, fd, ripgrep, gh, git-crypt, temurin JDK |
| JetBrains IDEs | **Toolbox** (not winget) | — | IDEA, GoLand, CLion, DataGrip, ... installs/updates/licenses live in the Toolbox app |
| VS workloads | VS Installer | `vs2026.vsconfig` | ManagedDesktop, NetWeb, NativeDesktop + explicit VC.Tools/Windows SDK (Rust's MSVC linker) |
| Rust toolchain | rustup (via scoop) + `apply.ps1` | `scoop.json` + rust section | stable (MSVC host) + rustfmt/clippy/rust-analyzer; mirrors `home/rust` (mac) & `home/linux-cli` (WSL) |
| Nerd fonts | scoop `nerd-fonts` bucket | ad hoc | deliberately not pinned (the full set is installed on LORE) |
| WSL user env | Home Manager | `../flake.nix#james` | zsh, nvim, git, tmux, CLI parity via `home/linux-cli` |
| PowerShell aliases | generated | `ps-aliases.ps1` | git/kubectl/docker/helm/terraform + shellAliases as PS functions |
| Hermes Agent | Home Manager + `apply.ps1` | `../home/hermes/` | Shared OpenRouter policy, AI context, Second Brain skills, native Windows install |

Hermes uses the same tracked `home/hermes/managed-config.yaml` and `SOUL.md` on
macOS, WSL, and native Windows. `apply.ps1` installs native Hermes when missing,
deploys those files, and sets the user-level vault and managed-policy paths.
Home Manager deploys the OpenRouter, CircleCI, Firecrawl, and Google user-client
material without placing plaintext secrets in Git or the Nix store. Native policy lives
in `%LOCALAPPDATA%\hermes\managed`; OAuth tokens and identity remain in the
normal Hermes home. `apply.ps1` also mirrors `home/ai/` and applies current-user
ACLs to secret-bearing files. It removes any native messaging service because
the continuous Slack gateway belongs to Grogu. See `../docs/HERMES.md` for
authorization and validation.

For a fresh machine, run `apply.ps1`, activate the WSL Home Manager target so
the SOPS bridge can deploy credentials, then rerun `apply.ps1` to apply Windows
ACLs and verify the native runtime.

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
