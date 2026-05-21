# Session State

**Last Updated:** 2026-05-21

## Current Status
All outstanding architectural issues in the Nix-Darwin and Home Manager configuration have been resolved, verified, and documented. The configuration now builds and activates successfully. The active changes are staged and ready to commit.

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
| `main` | Clean. Pushed through `e4e324d`. Session commits: `956ae38` (sops + mkPatDeployer), `669db69` (settings), `e4e324d` (settings). Parallel Pi-setup commits also landed: `c99622c`, `44708c8`, `81f9bfb`, `956f423`, `e1752b1`, `19d4824`. |

## Pending Work
- [ ] (optional) Narrow `github-sandbox-pat` scope from "RW everything" → `Contents:RW + Metadata:R`, re-encrypt, push, rebuild.
- [ ] On Darth: verify `age-keygen -y ~/.config/sops/age/keys.txt` matches the `&darth` pubkey; `git pull && sudo darwin-rebuild switch`. Will pick up both PATs automatically.
- [ ] On Renova: generate age key, add `&renova` to `.sops.yaml`, `sops updatekeys secrets/github-security-pat.enc secrets/github-sandbox-pat.enc`, push, rebuild.
- [ ] On Darth (after Renova): `sops updatekeys secrets/aws-credentials.enc` and uncomment the `secrets."aws-credentials"` block.
- [ ] Carryover: review bootstrapped `CLAUDE.md` inside `~/Git.Local/QRun-IO/qqq/` and commit it to QQQ's main.
- [ ] Carryover: (as projects rotate in) add additional Greater Goods Jira projects to `home/ai/4-preferences.yaml`.
- [ ] Carryover: (deferred) HIPAA / BAA / PHI policy layer.
- [ ] Carryover: optional disk follow-ups from 2026-05-13 (Website-Backend/src/test 13 GB, `~/Library/Application Support/Claude` 14 GB, Docker K8s ~34% baseline CPU).

## Key Reference

**`github-security-pat`** (classic PAT, org-wide security reads)
- Enc: `secrets/github-security-pat.enc` · Deploy: `~/Documents/Claude/Projects/Security Alerts/.github-pat` (mode 0600)
- Deployer: `home.activation.deployGithubSecurityPat` (via `mkPatDeployer`)

**`github-sandbox-pat`** (fine-grained PAT, RW everything on `GG-Sandboxes/james.maes`)
- Enc: `secrets/github-sandbox-pat.enc` · Deploy: `Security Alerts/.github-deploy-pat`, `ClaudeCode Setup/.github-deploy-pat` (both mode 0600)
- Deployer: `home.activation.deployGithubSandboxPat` (via `mkPatDeployer`)

**Pages site**
- URL: `https://improved-adventure-l4pmw97.pages.github.io/` (org-internal, auth-gated)
- Source: `main /`; landing page at repo root; dashboards under `dashboards/<name>/`. Dashboard agent commits only under `dashboards/*/` — root `index.html` and `README.md` are safe.

**Common**
- Age recipients (`.sops.yaml`): Dark-Horse + Grogu + Darth (Darth pubkey unconfirmed).
- Rotation: `sops -e --filename-override secrets/<name>.enc --input-type binary --output-type binary <plaintext> > secrets/<name>.enc`, commit, push, rebuild each host.
- Add a destination to an existing PAT: append to the `destinations = [ ... ]` list in `home/sops/default.nix`; missing folders are silently skipped.
