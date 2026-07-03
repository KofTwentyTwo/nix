# IntelliJ (Windows) + WSL Development Setup

Workflow this supports: **git from Ubuntu, coding/running/debugging (incl.
Docker testcontainers) from IntelliJ on Windows**, with all code living on
WSL ext4 for performance.

## The one rule

Code lives in WSL (`~/Git.Local/...`, ext4). IntelliJ reaches it over
`\\wsl.localhost\Ubuntu\...`. Never clone repos onto `C:` for WSL builds and
never build from `/mnt/c` — that path crosses the 9p filesystem boundary on
every file operation and is 10–50× slower.

## What Nix manages (nothing to do manually)

| Piece | Where | Notes |
|---|---|---|
| JDK 21 | `home/java/default.nix` | Matches qrunio `maven.compiler.release=21` and the mac's `openjdk@21` |
| Stable JDK path | `~/.jdk` (real dir, materialized) | Survives nix updates; the ONLY path IntelliJ should know. A real copy, not a symlink — Windows cannot traverse into Linux symlinks over 9p |
| `JAVA_HOME` | session var → `~/.jdk` | WSL-side mvn/gradle use the same JDK as the IDE |
| maven / gradle | `home/linux-cli` | On PATH in WSL |
| `core.autocrlf=input` | `flake.nix` git settings | Strips CRLF if a Windows editor sneaks one in |

## IntelliJ one-time configuration (GUI, per Windows machine)

1. **Open project**: File → Open → `\\wsl.localhost\Ubuntu\home\james\Git.Local\<repo>`.
   IDEA detects it as a WSL project.
2. **JDK**: File → Project Structure → SDKs → `+` → Add JDK →
   `\\wsl.localhost\Ubuntu\home\james\.jdk`. Name it `wsl-jdk21`. Use it as
   the project SDK. (Do NOT point at a `\nix\store\...` path — it changes on
   every update; `~/.jdk` is retargeted by Home Manager.)
3. **Maven**: Settings → Build Tools → Maven → Maven home path:
   `\\wsl.localhost\Ubuntu\home\james\.nix-profile\share\maven` (or leave
   IDEA's bundled Maven — it also runs fine; the JVM used is the WSL JDK
   from step 2 either way). Runner → JRE → `wsl-jdk21`.
4. **Terminal**: Settings → Tools → Terminal → Shell path: `wsl.exe`.
   Embedded terminals then land in the Home-Manager zsh.
5. **Line separator**: Settings → Editor → Code Style → General → Line
   separator: `Unix (\n)`. (`core.autocrlf=input` is the backstop.)
6. **Git**: nothing — IDEA auto-uses the WSL-side `git` for `\\wsl.localhost`
   projects, so GPG signing and the 1Password SSH agent work unchanged.

## Docker

Docker Desktop (WSL2 backend) serves both sides of the fence natively:
IntelliJ run configs / testcontainers talk to it from Windows, and the
`docker` CLI works inside Ubuntu (verified). No setup needed.

## Performance knobs

- `.wslconfig` (`C:\Users\james\.wslconfig`) is already tuned:
  `memory=96GB, processors=32, networkingMode=mirrored`.
- **Windows Defender** (optional, biggest remaining win for indexing): exclude
  the WSL VM process and IDE from real-time scanning. Run in an elevated
  PowerShell (e.g. via `gsudo`):

  ```powershell
  Add-MpPreference -ExclusionProcess "vmmem"
  Add-MpPreference -ExclusionProcess "vmmemWSL"
  Add-MpPreference -ExclusionProcess "wslservice.exe"
  Add-MpPreference -ExclusionProcess "idea64.exe"
  ```

  Security trade-off: files inside WSL lose real-time scanning. Skip if that
  is not acceptable.
- If indexing a large monorepo is still sluggish, the next step up is
  **JetBrains Gateway** (IDE backend runs inside WSL, thin client on
  Windows) — eliminates the 9p boundary entirely at the cost of thin-client
  UX quirks.

## Sanity checks

```bash
# in WSL — toolchain agrees with itself
echo $JAVA_HOME        # /home/james/.jdk
java -version          # openjdk 21.x
mvn -version           # Java version: 21.x, runtime: /home/james/.jdk

# from Windows (PowerShell) — the path IntelliJ uses must traverse
Test-Path '\\wsl.localhost\Ubuntu\home\james\.jdk\bin\java'   # must be True
Test-Path '\\wsl.localhost\Ubuntu\home\james\.jdk\release'    # must be True
```
