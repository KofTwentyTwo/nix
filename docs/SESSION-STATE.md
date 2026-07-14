# Session State

**Last Updated:** 2026-07-14 (Hermes primary-agent rollout)

## Hermes primary-agent rollout

Hermes is declaratively configured across macOS, WSL, and native Windows with shared AI context, Second Brain skills, OpenRouter `pareto-code` routing, smart approvals, checkpoints, GitHub/CircleCI/Atlassian tooling, pinned Firecrawl MCP, computer use, Gmail and Google Workspace, and Greater Goods Slack. Live checks passed for OpenRouter, AI context, local tools, GitHub APIs, CircleCI diagnostics, Atlassian MCP, and full-desktop computer use. Grogu alone owns the continuous Slack gateway plus its service credentials; Windows and other Macs remain interactive clients.

The rollout is committed and pushed as `57d0be4`, the final repository gate passes, and Dark-Horse is activated. Gmail is the primary Google integration; Calendar, Drive, Docs, Sheets, People, and Contacts use the same helper. Human account work remains: rotate CircleCI, populate the empty Firecrawl 1Password item, create and install the Greater Goods Slack app, create the Google Desktop OAuth client and complete per-runtime consent, and validate native Windows when LORE is online. The removed development credential also needs rotation because history may retain it. Darth, Grogu, LORE, and Renova were offline during fleet activation and must pull and activate when they reconnect.

## 🟢 DONE — Recovered uncommitted 2026-07-02 session from the old WSL clone (2026-07-03)

Before deleting the deprecated `/home/james/Git.Local/kof22/nix` clone, found
an entire uncommitted session (2026-07-02): `docs/WINDOWS-DEV.md` +
`docs/INTELLIJ-WSL.md` (Windows dev-env + IntelliJ/WSL architecture docs),
`home/java/default.nix` (Linux JDK 21 with materialized `~/.jdk` for
Windows-side IntelliJ over 9p), platform-conditional `JAVA_HOME` /
darwin-only `GRAALVM_HOME` in zsh, `core.autocrlf=input` in flake git config,
and the gnused serena fix (adopted — supersedes today's temp-file variant;
that session had independently found the same serena/mktemp bugs but never
committed). All ported into the canonical checkout; old clone deleted after.
NB the 2026-07-02 architecture note: Java WORK repos live ALL-WINDOWS on R:
(Temurin/scoop); WSL-ext4 + `~/.jdk` remains for WSL-side Java. The nix repo
itself is the sanctioned exception to "WSL must not operate on Windows-side
repos" (canonical checkout on R:, per James 2026-07-03).

## 🟢 DONE — sops fleet key: machine onboarding loop broken (2026-07-03)

- New shared `&fleet` age recipient added to all `.sops.yaml` rules except
  `aws-credentials.enc`; secrets re-encrypted via Dark-Horse (James approved).
  LORE now decrypts everything: `switch` is exit-0 with ZERO sops warnings;
  circleci-token + github-security-pat deployed (0600).
- **Fleet key ROTATED same day** (James approved): the first fleet private key
  leaked into a Claude session transcript via a sloppy readback check. New
  fleet key is `age1zd7vug4...h953mg`; rotation ran entirely ON LORE (machine
  key authorized `sops updatekeys` — no Mac needed, validating the model).
  Old key verified removed from all recipients. Lesson: verify op/secret
  readbacks with `Select-String -Quiet`, never `-like` on multi-line output.
- New-machine bootstrap is now: paste the fleet identity from 1Password into
  `~/.config/sops/age/keys.txt`. No updatekeys ceremony. Revocation = rotate
  fleet key + one updatekeys pass. Per-machine keys kept as extra recipients.
- ✅ Fleet identity stored in 1Password: Secure Note **"age fleet key (sops)"**
  (Private vault, id `3zxwe5pw64xwkj4ogvutuhld5e` — holds the ROTATED key; the
  first item was deleted with the burned key). NB for agents: `op item create`
  hangs on a piped stdin unless you feed it a JSON template on stdin.

## 🟢 DONE — Obsidian second brain wired into Claude Code (2026-07-03)

Implemented James's `claude-code-secondbrain-requirements.md` spec (see
`docs/PLAN-secondbrain.md` for gap analysis + decisions taken while AFK):

- **Vault:** `R:\Git.Local\KofTwentyTwo\second-brain` (= `/mnt/r/...` in WSL;
  Macs will use `~/Git.Local/KofTwentyTwo/second-brain`). Git-backed with a
  private remote: `github.com/KofTwentyTwo/second-brain` (created + pushed
  2026-07-03 with James's approval); consolidation pushes weekly.
- **New module `home/secondbrain/`**: SECOND_BRAIN_VAULT env, SessionStart
  (inject index.md + project note) / SessionEnd (daily-log stub) hook scripts,
  secondbrain-save + secondbrain-consolidate skills, vault bootstrap
  (clone-or-scaffold), weekly consolidation (systemd user timer Sun 18:00 on
  Linux, launchd on mac), and a LORE-only bridge that mirrors hooks (PowerShell
  ports), skills, CLAUDE.md, and settings fragments into Windows-native Claude
  Code at `C:\Users\james\.claude`.
- **home/claude/default.nix**: hooks registered via marker-based jq merge
  (drops entries containing "secondbrain", appends managed ones — GSD's Mac
  hooks untouched); `env.SECOND_BRAIN_VAULT` in userPrefs; MCP-budget warn
  (>5) in syncClaudeJson; `csharp-lsp` enabled; `terraform` plugin declared
  false (swap-in). `home/lib/agent-context.nix` gained the Second Brain
  directive (flows to Claude/Codex/Gemini bootstrap docs).
- **Acceptance (spec §9)**: fresh headless session from empty dir sees the
  injected index ✓; WSL settings hooks+env ✓; Windows bridge merge + PS1 hook
  run ✓; daily log stub written ✓; timer scheduled ✓; MCP count 2 (≤5) ✓;
  vault secret scan clean ✓; Darth darwin eval still green ✓. Live LLM
  decision-write test + consolidation idempotency pass: consolidation run
  started, verify journal. Obsidian added to windows/winget.json (not yet
  installed — run windows/apply.ps1).

## 🟢 DONE — LORE: R:\ checkout is now the working nix (2026-07-03)

**Machine:** LORE (Windows 11 + WSL Ubuntu). The canonical repo checkout is now
`R:\Git.Local\KofTwentyTwo\nix` on the Dev Drive (ReFS VHDX), shared with WSL:

- **WSL mount:** `R:` was not automounted (Dev Drive VHDX attaches after WSL's
  automount pass) → mounted at `/mnt/r` via drvfs and persisted in `/etc/fstab`
  (`R: /mnt/r drvfs rw,noatime,uid=1000,gid=1000,symlinkroot=/mnt/ 0 0`).
- **Flake path:** `~/.config/nix` in WSL is a symlink →
  `/mnt/r/Git.Local/KofTwentyTwo/nix`. This makes the Linux side match the macOS
  layout, so all `~/.config/nix` docs/scripts are correct everywhere. The zsh
  `switch` helper (home/zsh/default.nix) now uses `$HOME/.config/nix#james` on
  Linux; verified with a green `home-manager switch` (gen advanced) from the new
  path.
- **Line endings:** the Windows clone had `core.autocrlf=true` → 162 files CRLF
  in the working tree. Fixed: repo-local `core.autocrlf=false`, stripped `\r`,
  restaged (index sizes were stale — git flags size mismatch as modified without
  re-hashing). Invariant: keep this checkout all-LF.
- **git-crypt:** unlocked via symmetric key exported from the old WSL clone.
  Windows side got git-crypt 0.7.0 via scoop; `.git/config` filter entries were
  rewritten PATH-relative (`"git-crypt" smudge/clean`) so Windows git and WSL
  git each resolve their own binary. Both sides verified clean.
- **Old WSL clone** at `/home/james/Git.Local/kof22/nix` is now DEPRECATED —
  nothing references it; delete once comfortable.
- **Windows dev tooling:** new `windows/` module (`apply.ps1` + `winget.json` +
  `scoop.json` + `vs2026.vsconfig` + README) — the Windows analog of `switch`.
  winget = GUI/heavy apps (JetBrains Toolbox, Node LTS — installed 24.18.0),
  scoop = CLI tools (adopted the existing set), JetBrains IDEs stay managed by
  Toolbox (already installed with full fleet). Visual Studio 2026 install is
  wired up (edition in winget.json, workloads in vs2026.vsconfig, re-applied on
  existing installs via `setup.exe modify`) — NOT yet run; awaiting edition
  choice (Community/Professional/Enterprise → `Microsoft.VisualStudio.<edition>`).
- All of the above is uncommitted on `main` (working tree diff).

## Previous — Get this config running on WSL Ubuntu (2026-06-30)

**Goal:** Run the shared `./home` Home Manager modules on WSL Ubuntu 26.04
(x86_64) via standalone Home Manager. nix-darwin is untouched and mac-only.

**Repo location on WSL:** `/home/james/Git.Local/kof22/nix` (NOT `~/.config/nix`).
**WSL user:** `james`  ·  **home:** `/home/james`  ·  Linux git identity reuses
the macOS `userConfig` (same name/email/signing key); only paths differ.

### Done so far (code is ready, uncommitted — `git status` shows the diff)

- Enabled systemd in `/etc/wsl.conf` (`[boot] systemd=true`). **Needs a WSL
  restart to take effect** — that is why this session was paused.
- `flake.nix`: added a Linux `homeConfigurations."james"` output (additive;
  `darwinConfigurations` untouched) + `linuxUserConfig`/`linuxUsername` in the
  let block. Reuses the existing `homeconfig` module.
- Guarded the mac-only eval/build breakers behind `pkgs.stdenv.isDarwin`:
  - `home/updates/default.nix` — `launchd.agents` (darwin-only option).
  - `home/gpg/default.nix` — `pinentry_mac` → `pinentry-curses` on Linux.
  - `home/viscosity/default.nix` — whole module (macOS-only VPN app).
  - `home/default.nix` — `/opt/homebrew/*` `sessionPath` entries.

### Progress (2026-06-30 cont.)

- ✅ systemd live after restart; ✅ Determinate Nix 3.21 installed, daemon active.
- ✅ flake parses; `nix eval .#homeConfigurations.james...` got past the flake and
  into module eval.
- ⛔ **BLOCKER hit:** the working tree is git-crypt **LOCKED**. `home/ssh/default.nix`
  (and `home/ai/4-preferences.yaml`, `home/aws/config/*`) are still encrypted blobs,
  so Nix reads them as garbage → syntax error. Must `git-crypt unlock` before build.
- ✅ Installed `git-crypt` 0.8.0 into nix profile. (`_1password-cli` is unfree —
  skipped; would need NIXPKGS_ALLOW_UNFREE=1 --impure.)
- 🔑 The git-crypt symmetric key is encrypted to GPG key
  `62859E8ABE1FC2B7FCCB89080021767055740E6D` — the SAME key as commit signing.
  System gpg is `/usr/bin/gpg`, keyring currently EMPTY.

### ▶️ RESUME HERE

1. **Import the GPG secret key** (from 1Password). `gpg --import <file.asc>`. The
   private half is required — unlock + signing both need it. May be passphrase-
   protected → `git-crypt unlock` will trigger a pinentry prompt; if running non-
   interactively fails, have James run `git-crypt unlock` via the `!` prefix.
2. **Unlock:** `cd /home/james/Git.Local/kof22/nix && git-crypt unlock`
   (or `git-crypt unlock` with the repo's key). Verify `home/ssh/default.nix` now
   reads as Nix source, not `GITCRYPT` bytes.
3. **Re-eval / activate** (first run, HM not yet installed; `-b backup` saves clashing dotfiles):
   `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`
   `nix run home-manager/master -- switch -b backup --flake /home/james/Git.Local/kof22/nix#james`
   (NB: full build pulls the entire nerd-fonts set — large/slow first time.)
4. **Iterate** on eval/build errors. Expected remaining issues are *runtime* not
   build: zsh `switch`/help text still says `darwin-rebuild`; some activation
   scripts reference mac paths but self-guard.
5. **Import the GPG signing key** (so `git commit` works — `signByDefault=true`,
   format openpgp, fingerprint `62859E8ABE1FC2B7FCCB89080021767055740E6D`).
   James keeps the **secret key in 1Password**. After `op` CLI is installed +
   signed in (note WSL `op` usually integrates with the Windows 1Password app),
   pull the armored private-key block and `gpg --import` it — e.g.
   `op document get "<item>" | gpg --import` (item name TBD — ask James / search
   `op item list`). The public key alone won't sign; need the secret half.
   Decision: keep signing ON for Linux (do NOT set signByDefault=false).
6. Once green: `chsh -s $(which zsh)` if zsh isn't the login shell, commit the diff.

### Progress (2026-06-30 — activation + tool parity)

- ✅ First `home-manager switch` activated (gen 2). Fixed the one Linux activation
  breaker: `home/claude/default.nix` used BSD `/usr/bin/stat -f %Su` (7 sites) →
  now portable `stat -c %U … || /usr/bin/stat -f %Su` (mac falls through to BSD).
- ✅ Verified macOS UNHARMED: `nix eval .#darwinConfigurations.Darth...toplevel.drvPath`
  still evaluates; flake.lock untouched; nothing committed (HEAD still 7fafad7).
- ✅ Configs deployed (zsh 1010-line .zshrc, starship, ssh, git, tmux at
  ~/.config/tmux/, nvim, gpg) — all real /nix/store symlinks.
- ⚠️ GAP FOUND: the ~150 Homebrew formulae in modules/homebrew.nix are mac-only;
  Linux had almost none of the CLI utils (fd, rg, gh, htop/btop, helm, tofu…).
  fd missing breaks the fzf widgets.
  → Created **home/linux-cli/default.nix** (`lib.mkIf pkgs.stdenv.isLinux`,
  imported in home/default.nix) porting the curated CLI subset to Nix packages.
  Skipped mac-only / heavy-ML / GUI / mise-or-rustup-provided tools (documented
  in the module header). Name fixes applied: du-dust→dust, poppler_utils→
  poppler-utils, no-more-secrets→nms. Eval is green; switch building now.

### Remaining follow-ups

- [ ] Login shell still /bin/bash → `chsh -s ~/.nix-profile/bin/zsh`.
- [ ] zsh `switch` helper (home/zsh ~line 568) hardcodes `sudo darwin-rebuild
      switch` → make it `home-manager switch --flake …#james` on Linux.
- [ ] Nothing committed. When ready, commit the WSL port on a BRANCH (not main,
      per repo norm) so Macs are unaffected until they pull.
- [ ] `~/key` (exported GPG secret) still on disk — `shred -u ~/key` once happy.
- [ ] Optional: add psql client / more brew tools to home/linux-cli as wanted.

### Notes / decisions

- Chose **unified flake** (one `flake.nix`, shared `flake.lock`) over a separate
  `flake-linux.nix` — the repo's `flake-linux.nix.example`/`LINUX.md` describe the
  older separate-flake idea; we superseded it. Can delete those docs later.
- git-crypt binary isn't installed on WSL but the working tree is already
  decrypted (ai/ssh configs read as plaintext), so `home.file` sources are real.

---

**Last Updated (prior):** 2026-05-26 (evening)

## Current Status

`main` clean at `1016007 docs(claude): capture install-drift diagnosis + session permissions`, pushed to `origin/main`. Claude install-channel drift triaged: native install restored at `~/.local/bin/claude`, `/opt/homebrew/bin/claude` migrator path evicted, `~/.claude.json` user-owned with `mcpServers` populated. Open: re-login required on next claude launch (OAuth wiped during the loop). See `docs/PLAN-claude-install-drift.md` for the full diagnosis + post-reboot recovery steps if the migrator returns.

## What Was Done This Session (2026-05-26 evening — claude install drift)

- Diagnosed why `claude` kept hitting the first-launch setup wizard on every start: Claude's own auto-updater, finding `installMethod: "global"` in a clobbered `~/.claude.json`, kept reinstalling itself via npm into `/opt/homebrew/lib/node_modules/@anthropic-ai/` (root-owned because sudo credentials were cached during the session). Same loop documented in commit `a93b80f`.
- Restored the committed `a93b80f` `bootstrapClaude` eviction (had been removed earlier in the session under a wrong interpretation of "no cleanup in script"). The eviction's npm-channel target is correct policy; `/opt/homebrew` cleanup stays manual.
- Manually ran `bash claude.ai/install.sh` outside the activation context (where it actually succeeds — the activation-wrapped install fails silently in some cases), then `sudo darwin-rebuild switch` to apply `a93b80f`. After: `which claude` → `~/.local/bin/claude`, user-owned, `mcpServers` populated.
- Wrote `docs/PLAN-claude-install-drift.md` with diagnosis, manual recovery sequence, and an `fs_usage` recipe to catch the migrator's parent process if it returns.
- Recorded the incident as project memory (`project_claude_install_drift_2026_05_26`).
- Committed accumulated debug permissions in `.claude/settings.local.json` (sudo chown patterns, `rm -f` of stray claude paths, `fs_usage` invocations, etc.) — useful for future sessions debugging the same pattern.

## What Was Done This Session (2026-05-26 — earlier work)

- Fixed `mkPatDeployer` so a missing age key skips only PAT deployment instead
  of aborting later Home Manager activations.
- Removed the stale `claude-skills-gsd` flake update from the `switch` helper
  and aligned generated Codex/Gemini bootstrap text with
  `~/.ai/5-learnings.md`.
- Tightened broad Claude permission patterns in both declared and local
  settings.
- Added `scripts/check-repo.sh` and `.markdownlint-cli2.yaml`, registered the
  check script with Home Manager, and cleaned ShellCheck issues across existing
  scripts.
- Promoted the pending learning queue into `home/ai/5-learnings.md`, moved raw
  queue files to `learnings_to_process/processed/`, ignored `.serena/`, and
  removed `result` from git tracking while leaving the local build symlink
  ignored.

## What Was Done This Session (2026-05-21)

**Tmux Pane Redraw Latency**
- Created `scripts/git-pane-info.sh` to fetch Git repository status asynchronously. Uses directory-based locking (`/tmp/git-cache-$(id -u)/<hash>.lock`) to prevent concurrent query stampedes and caches results.
- Integrated the async script into the `pane-border-format` inside `home/tmux/default.nix`, replacing the previous slow synchronous inline Git calls.
- Registered the script in `home/scripts/default.nix`.

**LaunchAgent Race Condition**
- Removed the manual `system.activationScripts.setupUpdateChecker` from `flake.nix`.
- Defined a native Home Manager launchd agent `launchd.agents.check-updates` inside `home/updates/default.nix`. This resolves the activation race condition and registers the agent cleanly in user space.

**Neovim Plugin Config & Script Hardening**
- Fixed a typo in `home/nvim/config/lua/plugins/lsp.lua` changing `"mason-org/mason.nvim"` to `"williamboman/mason.nvim"`.
- Hardened `scripts/check-updates.sh` by dynamically resolving the tracking remote and branch via `git rev-parse --abbrev-ref @{u}` instead of using a hardcoded `origin/main` branch.

**Documentation & Code Comments Improvements**
- Added explanatory code comments to `home/tmux/default.nix` clarifying the async nature of `git-pane-info.sh` and how it prevents pane border lag.
- Populated the `## Current Scripts` section of `scripts/README.md` with complete, detailed descriptions of all 24 custom scripts.
- Updated `README.md` script count and lists, adding `git-pane-info.sh` to the Tmux Utilities section.
- Updated `docs/TODO.md` to reflect completed tasks under "Recently Completed".

**`github-sandbox-pat` (fine-grained, RW everything on `GG-Sandboxes/james.maes`)**
- Encrypted to `secrets/github-sandbox-pat.enc` via sops with the three current age recipients (darth + dark_horse + grogu). `.sops.yaml` got a matching `creation_rules` entry. Plaintext shredded after encryption.
- Filename pivot mid-session: started as `.github-pat-sandbox`; the dashboard agent declared it expects `.github-deploy-pat`. Renamed before activation.

**`mkPatDeployer` helper in `home/sops/default.nix`**
- Extracted `mkPatDeployer = { name, encFile, destinations }: ...` — emits a `home.activation` entry that decrypts a sops file and atomically deploys it (mktemp in dest dir → mv) to every path in `destinations`. Per-destination skip if the parent dir is missing; whole-deployer skip if no age key.
- Existing `deployGithubSecurityPat` migrated onto the helper. Legacy-symlink cleanup split into its own `cleanupLegacyGithubSecurityPat` activation entry.
- Verified on Dark-Horse: all three activations ran; SHA-256 of `.github-deploy-pat` in both destinations matches the sops-decrypted source (`37e4ec36…0ce46`).

**`GG-Sandboxes/james.maes` repo bootstrap (via `gh api`)**
- Repo was empty with `default_branch: develop` (which didn't exist). Created `main` with `README.md` + bootstrap `index.html` via Contents API; PATCHed `default_branch` to `main`.
- Enabled Pages from `main /`. First build succeeded in 43s. URL: `https://improved-adventure-l4pmw97.pages.github.io/` (auth-gated because the repo is `internal`-visibility).

**Personal sandbox landing page**
- Wrote a clean single-file `index.html` (light + dark mode, no JS, no build step) with two dashboard cards.
- Scrubbed two rounds of Claude/Cowork branding: intro paragraph, then meta description + AI Updates card description.
- Both dashboards deployed during session: `dashboards/security/index.html` (77 KB) and `dashboards/ai-updates/index.html` (50 KB). Promoted AI Updates card from "Soon" → "Live" once it appeared.

## Active Branches

| Branch | Status |
|--------|--------|
| `main` | Clean after pushing `1016007` to `origin/main`. |

## Pending Work

- [ ] **Open a fresh terminal, run `claude`** — expect the OAuth login flow (tokens were wiped during the install-drift loop). Verify plugins/MCP/permissions load from `~/.claude/settings.json` (untouched).
- [ ] If `/opt/homebrew/bin/claude` reappears: use the `fs_usage` instrumentation in `docs/PLAN-claude-install-drift.md` to ID the migrator's parent process. Consider extending `a93b80f`'s eviction to cover `/opt/homebrew/bin/claude` + `/opt/homebrew/lib/node_modules/@anthropic-ai` if it recurs.
- [ ] On Darth: verify `age-keygen -y ~/.config/sops/age/keys.txt` matches the `&darth` pubkey; pull + rebuild to pick up new generalized variables.
- [ ] On Renova: generate age key, add `&renova` to `.sops.yaml`, run `sops updatekeys` across secrets, and rebuild.
- [ ] (Long-term) Migrate shared CLI tools from `modules/homebrew.nix` into standalone Home Manager package sets to enable 1-click Linux bootstrap.

## Session 2026-07-14 — Always-on GitHub auth (gh + git, no logins)

**Goal:** `gh` and `git` work on every machine forever without `gh auth login` or running `secure`.

- git-over-SSH was already declarative (1Password agent, `home/ssh`); the gaps were imperative `gh` keychain auth and no HTTPS credential helper at all.
- Encrypted the 1Password `GITHUB_TOKEN` item (classic `ghp_` PAT, **no expiration**, broad scopes) to `secrets/github-token.enc` (fleet + all machine recipients). Piped `op item get` → `sops` directly; no plaintext ever touched disk.
- `home/sops/default.nix`: new `deployGithubToken` via `mkPatDeployer` → `~/.config/secrets/github-token` (mode 0600).
- `home/zsh/default.nix`: exports `GITHUB_TOKEN` in every interactive shell (same env var `secure` loads from 1Password; now unconditional and 1Password-independent).
- `flake.nix` `programs.git`: `credential."https://github.com".helper = "!gh auth git-credential"` (+ gist) — headless HTTPS git auth through gh.
- Verified on Dark-Horse after `darwin-rebuild switch`: `gh auth status` shows `(GITHUB_TOKEN)`; `GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/KofTwentyTwo/nix.git` succeeds. Old keychain login remains as an inert fallback.
- Follow-up (optional): the PAT has very broad scopes (`admin:org`, `delete_repo`, …). To narrow, mint a lesser no-expiry classic PAT and re-encrypt the same file.
- Unrelated: brew cask `ecamm-live` 4.5.8→4.5.9 upgrade failed mid-switch and cleanly self-reverted to 4.5.8; retries on a future switch.
