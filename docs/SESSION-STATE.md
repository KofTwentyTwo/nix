# Session State

**Last Updated:** 2026-05-20

## Current Status
Second PAT added — repo-scoped read/write fine-grained PAT for `GG-Sandboxes/james.maes`, deployed to two Cowork project folders for dashboards that publish to that sandbox repo. Refactored `home/sops/default.nix` to introduce a `mkPatDeployer` helper that the existing org-wide security PAT now uses too. Both PATs decrypt at activation time to mode-0600 regular files (sandbox-friendly).

## Prior Session (2026-05-19)
GitHub fine-grained PAT for org-wide security alert reads (greater-goods + gg-engineering + gg-devops + gg-sandboxes) deployed via sops + a `home.activation` script. Consumed by the Claude Cowork morning-digest dashboard. Pivoted mid-session from sops-nix symlink deployment to a regular-file deployment because the Cowork sandbox can't follow symlinks pointing outside its mount points.

## What Was Done This Session (2026-05-20)

**Second PAT: `github-sandbox-pat` for `GG-Sandboxes/james.maes` (repo-scoped RW)**
- User created a fine-grained PAT on github.com with every available repo permission set to Read & Write (Contents, Actions, Pages, Workflows, Webhooks, etc.) scoped only to `GG-Sandboxes/james.maes`. Pasted to `/tmp/token`; encrypted with `sops -e --filename-override secrets/github-sandbox-pat.enc ...` to `secrets/github-sandbox-pat.enc`; plaintext shredded.
- `.sops.yaml` got a third `creation_rules` entry for `github-sandbox-pat.enc` mirroring the security-pat recipient set (darth + dark_horse + grogu).
- Filename pivot mid-session: started as `.github-pat-sandbox`, the dashboard agent declared it expects `.github-deploy-pat`; renamed before activation.

**Refactor: `mkPatDeployer` helper**
- Extracted a let-binding `mkPatDeployer = { name, encFile, destinations }: ...` that emits a single `home.activation` entry which decrypts the named sops file and atomically deploys it (mktemp in the destination dir → mv) to every path in the destinations list. Per-destination skip if the parent dir is missing; whole-deployer skip if no age key.
- Migrated existing `deployGithubSecurityPat` to use the helper. Split the legacy-symlink/orphan-plaintext cleanup into its own `cleanupLegacyGithubSecurityPat` activation entry — keeps the helper purely about "decrypt → atomic write to N paths."

**Verified on Dark-Horse**
- `sudo darwin-rebuild switch --flake .` logged all three activations: `cleanupLegacyGithubSecurityPat`, `deployGithubSandboxPat` (two destinations), `deployGithubSecurityPat` (one destination).
- Deployed files: `Security Alerts/.github-pat` (41 B, classic PAT), `Security Alerts/.github-deploy-pat` (94 B, fine-grained), `ClaudeCode Setup/.github-deploy-pat` (94 B). All mode 0600.
- SHA-256 of both deployed copies of `.github-deploy-pat` matches the sops-decrypted source (`37e4ec36…0ce46`) — round-trip clean.

## Prior Session (2026-05-19)

**Token encryption + multi-machine recipients**
- Generated a classic PAT on GitHub with `security_events` + `read:org` scope (covers Dependabot, code-scanning, secret-scanning across all four orgs in one token; fine-grained PATs can't span multiple resource owners).
- Encrypted to `secrets/github-security-pat.enc` via sops with three recipients: `&darth` (pre-existing), `&dark_horse` (newly added), `&grogu` (newly added).
- `.sops.yaml` updated with the new machine pubkeys and a creation rule for the PAT file.
- Discovered `aws-credentials.enc` is encrypted only to `&darth` — was blocking sops-install-secrets fail-fast on every non-Darth host. Commented out the AWS secret declaration with restore instructions inline.

**Pivot: Cowork sandbox can't see sops-nix symlinks**
- Initial deployment via sops-nix landed `~/.github-security-pat` as a symlink → `~/.config/sops-nix/secrets/github-security-pat`. The dashboard's morning digest runs in a sandboxed task that only mounts the project folder + `~/Git.Local/dmd`; symlinks targeting `~/.config/sops-nix/...` dangle from inside.
- Replaced `secrets."github-security-pat"` with `home.activation.deployGithubSecurityPat`, which `sops --decrypt`s directly to a real file at `~/Documents/Claude/Projects/Security Alerts/.github-pat` (mode 0600, atomic mv via mktemp in the destination folder).
- Added idempotent transitional cleanup of the old symlink + orphan plaintext at `~/.config/sops-nix/secrets/github-security-pat`, guarded by `-L` / `-f` tests so it only fires when the legacy layout exists.

**Verified**
- Dark-Horse: dashboard reads the token at the project path; SHA256 matches the original upload (`36fdca09…b86bcd`).
- Grogu: previously deployed via the symlink pattern; on next `darwin-rebuild switch` there, the activation script will self-clean orphans and (correctly) skip the project-folder deploy.

**CLAUDE.md updates**
- New "Patterns → Secrets" bullet documenting both backends and the sandboxed-consumer exception (when to bypass sops-nix's symlink and use `home.activation`).
- Known Issues entries for the AWS disablement and deferred-machine status.

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Local diff: `home/sops/default.nix` (helper refactor), `.sops.yaml` (new creation rule), `secrets/github-sandbox-pat.enc` (new), `.claude/settings.local.json` (session permissions). Not yet committed. |

## Pending Work — `GG-Sandboxes/james.maes` Pages deploy
- [ ] User: confirm with the Cowork dashboard agent that `Security Alerts/.github-deploy-pat` is present (it is, mode 0600). Fire a one-shot deploy.
- [ ] User: in `GG-Sandboxes/james.maes` repo Settings → Pages, enable Pages. Default branch is `develop` (not `main`) — set Pages source accordingly, or create a `main` branch first if the dashboard prefers that.
- [ ] If desired later, narrow the PAT scope to `Contents:RW + Metadata:R` only (currently RW-everything per user's explicit choice on 2026-05-20 for speed) and re-encrypt.

**Carryover PAT-related (waiting on host access):**
- [ ] On Darth: confirm `age-keygen -y ~/.config/sops/age/keys.txt` matches the `&darth` entry in `.sops.yaml`. If yes, `git pull && sudo darwin-rebuild switch`. If no, replace in `.sops.yaml` and re-key.
- [ ] On Renova: `age-keygen -o ~/.config/sops/age/keys.txt` (likely no key yet), paste pubkey, add `&renova` to `.sops.yaml`, `sops updatekeys secrets/github-security-pat.enc`, push.
- [ ] On Darth (when accessible): `sops updatekeys secrets/aws-credentials.enc` after Renova's pubkey is in the file, then uncomment the `secrets."aws-credentials"` block.

**Carryover (open):**
- [ ] Sync Darth / Renova: `git pull && sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)`
- [ ] From inside `~/Git.Local/QRun-IO/qqq/`: review the bootstrapped `CLAUDE.md` and commit to QQQ's main branch
- [ ] (optional) Decide whether to put `claude-hud@claude-hud` + the `jarrodwatts/claude-hud` marketplace into Nix
- [ ] (as projects rotate in) Add additional Greater Goods Jira projects to `home/ai/4-preferences.yaml`
- [ ] (deferred) HIPAA / BAA / PHI policy layer
- [ ] Disk follow-ups from 2026-05-13 still optional (Website-Backend/src/test 13GB, ~/Library/Application Support/Claude 14GB, Docker K8s ~34% CPU)

## Key Reference

**`github-security-pat` (classic PAT, org-wide security alert reads)**
- Encrypted source: `secrets/github-security-pat.enc` (recipients: darth + dark_horse + grogu)
- Deployed path: `~/Documents/Claude/Projects/Security Alerts/.github-pat` (mode 0600)
- Deployer: `home.activation.deployGithubSecurityPat` in `home/sops/default.nix` (via `mkPatDeployer`)

**`github-sandbox-pat` (fine-grained PAT, RW everything on `GG-Sandboxes/james.maes`)**
- Encrypted source: `secrets/github-sandbox-pat.enc` (recipients: darth + dark_horse + grogu)
- Deployed paths: `~/Documents/Claude/Projects/Security Alerts/.github-deploy-pat`, `~/Documents/Claude/Projects/ClaudeCode Setup/.github-deploy-pat` (both mode 0600)
- Deployer: `home.activation.deployGithubSandboxPat` in `home/sops/default.nix` (via `mkPatDeployer`)

**Common**
- Age recipients in `.sops.yaml`: Dark-Horse (`age1txsv7msn8ydlwr5nwhn3vw6cqjf6kezwjxtrjphzmfmn9pdgly5qsf0m5u`), Grogu (`age1vt8rn4ndve3qhjejv8zqadv9q5lt0hur0ql50xpeguggau4vr37srmluug`), Darth (`age17x3xfs46rcxvlu0a6pv3kjnhx8qsakl5w92s6x3kt9s5kpa9cpls37lxs8`, unconfirmed).
- Rotation: `sops -e --filename-override secrets/<name>.enc --input-type binary --output-type binary <plaintext-file> > secrets/<name>.enc`, commit, push, rebuild each host.
- Adding a destination for an existing PAT: append to the `destinations = [ ... ]` list in `home/sops/default.nix`. Missing folders are skipped per-destination, so unbuilt projects don't block other deploys.
