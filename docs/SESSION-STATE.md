# Session State

**Last Updated:** 2026-05-26 (evening)

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
