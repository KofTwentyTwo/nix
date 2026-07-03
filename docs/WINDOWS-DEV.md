# Windows-Native Dev Setup (Lore)

The all-Windows counterpart to `docs/INTELLIJ-WSL.md`, for repos where IDE
performance matters most (daily IntelliJ work). Decision rule: **one side per
repo** — Java work repos live all-Windows on the Dev Drive; infra/config
repos (this one) stay in WSL. Never split one repo's operations across the
WSL boundary.

Set up 2026-07-02 on Lore. Windows state is NOT nix-managed — this doc is the
record; re-run the steps on a new machine.

## Layout

| Thing | Path |
|---|---|
| Dev Drive | `R:` (256 GB expandable VHDX at `C:\DevDrive.vhdx`, ReFS, Defender performance mode) |
| Repos | `R:\Git.Local\<org>\<repo>` (mirrors WSL `~/Git.Local` layout) |
| Home-path convenience | `C:\Users\james\Git.Local` → junction → `R:\Git.Local` |
| JDK 21 (Temurin, scoop) | `C:\Users\james\scoop\apps\temurin21-jdk\current` — stable across updates; the path IntelliJ uses for all-Windows projects |
| Boot re-attach | Scheduled task `AttachDevDrive` (SYSTEM, ONSTART) runs `diskpart /s C:\ProgramData\DevDrive\attach.txt` — manually created VHDXs do not remount on their own |

## Git (Windows-side, global config)

All done — recorded here for rebuilds:

```text
user.name  James Maes          user.email jmaes@dmdbrands.com
core.autocrlf true             init.defaultBranch main
fetch.prune true               push.autoSetupRemote true
core.sshCommand C:/Windows/System32/OpenSSH/ssh.exe
gpg.format ssh
user.signingkey key::ssh-ed25519 …kRZT  ("908State St" — the key GitHub accepts)
gpg.ssh.program C:/Windows/System32/OpenSSH/ssh-keygen.exe
gpg.ssh.allowedSignersFile C:/Users/james/.config/git/allowed_signers
commit.gpgsign true
```

Why these:
- **`core.sshCommand` → Windows OpenSSH**: Git for Windows' bundled ssh cannot
  reach the `\\.\pipe\openssh-ssh-agent` named pipe that the 1Password
  desktop app serves. Windows OpenSSH can. Same 5 keys as the WSL bridge.
- **SSH signing, not GPG**: mac/WSL sign with the openpgp key (62859E8A…);
  Windows signs with the 1Password-held `908State St` SSH key — no GPG
  keyring to maintain on Windows, private key never touches disk. The key is
  registered on GitHub as BOTH auth and signing key → commits show Verified.
- **`autocrlf=true`** on Windows clones (checkout CRLF, commit LF);
  `autocrlf=input` guards the WSL side. Both normalize to LF in the repo.

## Cloning

From PowerShell (or IntelliJ's Get from VCS):

```powershell
cd R:\Git.Local\qrunio
git clone git@github.com:QRun-IO/<repo>.git
```

1Password pops an approval for first agent use per session. Bulk-clone an
org (Windows equivalent of `gclo`):

```powershell
gh repo list QRun-IO --limit 200 --json sshUrl -q '.[].sshUrl' |
  ForEach-Object { git clone $_ }
```

## IntelliJ for all-Windows projects

- Open from `R:\Git.Local\...` (or the `C:\Users\james\Git.Local` junction).
- SDK: `C:\Users\james\scoop\apps\temurin21-jdk\current` — name it
  `win-jdk21`. (WSL projects keep using `wsl-jdk21` → `\\wsl…\.jdk`.)
- Everything else is IntelliJ defaults — no WSL settings apply.

## Maintenance

- `scoop update temurin21-jdk` — `current` re-links; IntelliJ path survives.
- Dev Drive full? `Resize-VHD` (it's expandable; 256 GB cap) or new VHDX.
- Trust check: `fsutil devdrv query R:` should say trusted, filters allowed.
- To undo entirely: delete task `AttachDevDrive`, detach VHDX, delete
  `C:\DevDrive.vhdx` + junction. Repos are just clones — nothing unique.
