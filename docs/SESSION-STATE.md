# Session State

**Last Updated:** 2026-05-13

## Current Status
System maintenance pass: global permissions expanded, tmux-lock CPU-leak bug fixed at root, praesidium K8s cluster torn down, and ~213 GiB of disk reclaimed. All changes committed and pushed; `darwin-rebuild switch` already run by user.

## What Was Done This Session

**Global permissions** (in `home/claude/default.nix`)
- Added Terragrunt block (8 entries) — `init`, `plan`, `apply`, `taint`, `run`, `state`, `output`, `validate`. Comment flags the deliberate divergence from the existing terraform/tofu "no apply" policy.
- Expanded "AWS SSO credential rotation" section with `aws sso list-account-roles:*` and `/Users/james.maes/bin/get-gg-prod-bg-creds.sh`.
- New "AWS CLI" block (15 entries): `sts:*`, `ssm:*`, `eks:*`, scoped `kms`/`iam`/`backup`/`ec2`/`s3api`/`dynamodb` inspection verbs.
- Commit: `bcef385 feat(claude): allow terragrunt and AWS read-only verbs in agent permissions`.

**tmux-lock CPU leak fix** (`scripts/tmux-lock.sh`)
- Root cause: foreground `eval` of screensaver with no `trap` → on tmux pane SIGHUP the bash parent died, screensaver child (`perl`/asciiquarium, bash/`pipes.sh`) orphaned to PID 1 and pinned a core forever. Found 7 such orphans burning ~460% CPU combined across 2–12 day lifetimes.
- Added `cleanup() { pkill -P $$; tput cnorm; }` with trap on EXIT/INT/TERM/HUP. Reaps direct children on abnormal exit.
- Hardcoded `SCREENSAVER="cmatrix -s"` — dropped random selection over asciiquarium/pipes.sh/cbonsai/lavat/tty-clock (the busy-loop ones pinned cores; cmatrix stays under 5%).
- Commit: `0ddac79 fix(tmux): stop screensaver children from leaking as CPU-pinning orphans`.

**Process hygiene**
- Killed 36 stale/orphaned processes total: 21 old `tmux-lock.sh` parents (running pre-rebuild code, cycling through random screensavers), 7 cmatrix instances (some 12 days old), 5 lavat instances, 3 stale `claude` sessions (14d, 6d, 2d uptime).

**Praesidium K8s teardown**
- 18 running containers stopped via `kubectl delete namespace praesidium praesidium2-local`.
- 3 PVCs + 3 PVs (postgres, cos, minio) cascade-deleted (Delete reclaim policy).
- 4 docker-compose-era named volumes removed: `praesidium_minio_data`, `praesidium_openclaw_state`, `praesidium_pgdata`, `praesidium_worker_agents`.
- Other 8 projects' Docker volumes (command-center, kof22, me-health-portal, mes-assembly-server, multica, paperclip-loaded, voyage, wms-admin-agent) intentionally preserved.
- VM CPU dropped from 130–143% → 34%. Kubernetes itself left enabled.

**Disk reclamation (+213 GiB available, 52 → 265 GiB)**
- 8 safe Library caches deleted: Adobe Camera Raw 2 (7.9 GB), terragrunt (4.6 GB), JetBrains (4.5 GB), ms-playwright (2.1 GB), node-gyp (1 GB), 3× ShipIt update payloads (todesktop, antigravity, lens-desktop-updater) — 23.5 GB.
- Docker build cache pruned: 6.5 GB (inside Docker.raw).
- Kof22 Tier 1 build artifacts removed: `Website-Backend/target` (14 GB, untouched 7 weeks), Jarvis `build-devoverlay` + 5 dormant package `.build` dirs + 3 mcp-servers `.build` + jarvis-diag `.build` — 18.8 GB.
- TM local snapshots purged (`tmutil deletelocalsnapshots`): unpinned everything we'd deleted; 19 → 0 snapshots.

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Clean. Two session commits (`bcef385`, `0ddac79`) already pushed to `origin/main`. |

## Pending Work
Carryover from prior session:
- [ ] Sync Grogu / Darth / Renova: `git pull && sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)`
- [ ] From inside `~/Git.Local/QRun-IO/qqq/`: review the bootstrapped `CLAUDE.md` and commit to QQQ's main branch
- [ ] (optional) Decide whether to put `claude-hud@claude-hud` and the `jarrodwatts/claude-hud` marketplace into Nix
- [ ] (as projects rotate in) Add additional Greater Goods Jira projects to `home/ai/4-preferences.yaml`
- [ ] (deferred) HIPAA / BAA / PHI policy layer

Opt-in follow-ups from this session:
- [ ] Investigate `~/Git.Local/Kof22/Website-Backend/src/test` (13 GB — anomalously large; possibly checked-in test fixtures candidate for git-lfs migration)
- [ ] Optionally clean `~/Library/Application Support/Claude` (14 GB — old project sessions and MCP caches)
- [ ] Disable Docker Desktop Kubernetes if not needed (would reclaim the remaining ~34% VM baseline CPU)

## Key Reference
- 21 tmux panes were unlocked when we killed their old lock-script parents. They'll re-lock with the new (cmatrix-only + trap) script on next 30-min idle, via the updated `lock-after-time 1800` setting.
- macOS daily APFS local snapshots will resume on the next TM backup cycle — that's normal; today's purge just surfaced freed space immediately.
- Docker.raw apparent size (`ls -lh`) is sparse — real disk footprint is ~27 GB. Don't confuse the two.
