# Session State

**Last Updated:** 2026-05-19

## Current Status
GitHub fine-grained PAT for org-wide security alert reads (greater-goods + gg-engineering + gg-devops + gg-sandboxes) deployed via sops + a `home.activation` script. Consumed by the Claude Cowork morning-digest dashboard. Pivoted mid-session from sops-nix symlink deployment to a regular-file deployment because the Cowork sandbox can't follow symlinks pointing outside its mount points. Working tree clean; four commits pushed to `main`.

## What Was Done This Session

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
| `main` | Clean. Four session commits (`f9f10cc`, `05cc4ed`, `2b5f19d`, `112b317`) pushed to `origin/main`. |

## Pending Work
**PAT-related (waiting on host access):**
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
- PAT canonical path: `~/Documents/Claude/Projects/Security Alerts/.github-pat` (mode 0600, deployed by `home.activation.deployGithubSecurityPat` in `home/sops/default.nix`)
- Encrypted source: `secrets/github-security-pat.enc` (recipients: darth + dark_horse + grogu)
- Dark-Horse pubkey: `age1txsv7msn8ydlwr5nwhn3vw6cqjf6kezwjxtrjphzmfmn9pdgly5qsf0m5u`
- Grogu pubkey: `age1vt8rn4ndve3qhjejv8zqadv9q5lt0hur0ql50xpeguggau4vr37srmluug`
- `/tmp/token` on Dark-Horse still has the plaintext PAT — safe to `rm` whenever.
- Rotation: `sops -e --filename-override secrets/github-security-pat.enc --input-type binary --output-type binary <new> > secrets/github-security-pat.enc`, commit, push, rebuild each host.
