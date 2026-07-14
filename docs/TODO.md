# TODO

Active tasks and future improvements for the Nix configuration.

## Active Tasks

- [ ] Complete the Hermes integration and Second Brain coverage plan in `docs/PLAN-hermes-integration.md`: verify OpenRouter model routing, define scoped Git/CircleCI/Slack/email/computer access, implement declarative configuration, and validate the deployed result.
  - [x] Run the final repository gate and activate Dark-Horse.
  - [ ] Operator: create and install the Greater Goods Slack app, then SOPS-encrypt its two tokens.
  - [ ] Operator: create the Gmail and Google Workspace Desktop OAuth client, SOPS-encrypt it, and consent on each runtime.
  - [ ] Operator: add the Firecrawl subscription key to the empty 1Password item, then create `secrets/firecrawl-api-key.enc`.
  - [x] Operator: reauthenticate `gh`, then verify GitHub repository and workflow API access.
  - [ ] Operator: rotate and redeploy the known-exposed CircleCI personal token.
  - [x] Operator: verify or grant macOS Accessibility and Screen Recording consent.
  - [ ] Operator: run the native Windows apply, WSL switch, and second apply on LORE, then validate Hermes, Codex, Claude, and secret ACLs.
  - [ ] Operator: rotate the development credential removed from `home/ai/5-learnings.md` because repository history may retain it.
  - [x] Operator: remove the unsafe broad Claude permission entries reported by `scripts/check-repo.sh`.
- [ ] Verify post-claude-install-drift recovery: open a fresh terminal, run `claude`, re-login (OAuth wiped 2026-05-26), confirm plugins/MCP/permissions load. If `/opt/homebrew/bin/claude` reappears, use `docs/PLAN-claude-install-drift.md` (fs_usage recipe) to ID the migrator's parent process and decide whether to extend `a93b80f`'s eviction.
- [ ] On Darth: verify `age-keygen -y ~/.config/sops/age/keys.txt` matches the `&darth` pubkey in `.sops.yaml`; pull + rebuild; `sops updatekeys secrets/github-sandbox-pat.enc` for both PATs if recipient set changes
- [ ] On Renova: generate age key, share pubkey, add `&renova` to `.sops.yaml`, `sops updatekeys secrets/github-security-pat.enc secrets/github-sandbox-pat.enc`, pull + rebuild
- [ ] On Darth (after Renova pubkey added): `sops updatekeys secrets/aws-credentials.enc` and uncomment the `secrets."aws-credentials"` block in `home/sops/default.nix`
- [ ] Commit the staged bugs/drifts and HTML Summary patches to origin (2026-05-20)
- [ ] From inside `~/Git.Local/QRun-IO/qqq/`: review the bootstrapped `CLAUDE.md` and commit it to QQQ's main branch so it travels with the codebase
- [ ] (optional) Decide whether to put `claude-hud@claude-hud` and the `jarrodwatts/claude-hud` marketplace into Nix so claude-hud activates on every machine
- [ ] (as projects come into rotation) Add additional Greater Goods Jira projects beyond `MH` to `home/ai/4-preferences.yaml`
- [ ] (deferred) HIPAA / BAA / PHI policy layer for healthcare context — flagged as future work in `~/.ai/5-learnings.md`
- [ ] Test opencode TUI launch and MCP server connections (interactive)
- [ ] Diff remote machine (100.76.144.59) brew packages against flake when online
- [ ] Remaining audit: #22 (permission drift)
- [ ] (opt) Investigate `~/Git.Local/Kof22/Website-Backend/src/test` — 13 GB of "test source"; likely candidate for git-lfs or .gitignore
- [ ] (opt) Clean `~/Library/Application Support/Claude` (14 GB of old project sessions + MCP caches)
- [ ] (opt) Disable Docker Desktop Kubernetes to reclaim ~34% baseline VM CPU (control-plane idle cost)
- [ ] (Linux Portability) Add stand-alone `homeConfigurations` target inside `flake.nix` to support Linux builds alongside macOS Darwin.

## Recently Completed

- [x] Always-on GitHub auth: `secrets/github-token.enc` (no-expiry classic PAT from 1Password `GITHUB_TOKEN`) → `~/.config/secrets/github-token` → `GITHUB_TOKEN` exported in every shell; `gh` authenticated without `gh auth login`, HTTPS git via `!gh auth git-credential` helper in `flake.nix`; verified end-to-end on Dark-Horse (2026-07-14)
- [x] Claude install-channel drift triaged: restored `a93b80f` eviction (had been removed mid-session under wrong interpretation), reinstalled native `~/.local/bin/claude`, applied via `darwin-rebuild switch`, captured diagnosis + recovery in `docs/PLAN-claude-install-drift.md`, committed both as `1016007` (2026-05-26)
- [x] GitHub auth recovered: `gh auth status` is valid again on this machine, so repository and workflow access can be verified without reauthentication
- [x] Repo hardening pass: fixed review findings, added `scripts/check-repo.sh`, promoted pending learnings, removed tracked `result`, and verified with the full repo gate (2026-05-26)
- [x] Resolved tmux pane border redraw latency by querying Git repo and branch asynchronously via `git-pane-info.sh` (2026-05-21)
- [x] Resolved Nix-Darwin vs Home Manager LaunchAgent activation race condition by defining native Home Manager `launchd.agents.check-updates` (2026-05-21)
- [x] Fixed Neovim `mason.nvim` plug-in repository typo and hardened `check-updates.sh` branch tracking using dynamic upstream resolution (2026-05-21)
- [x] Executed Deep QA Search and patched active defects: resolved Grogu configuration drift, robustified devShell git-crypt auto-unlock hooks, standardized session paths, and generalized hardcoded user directories in Claude's permissions (2026-05-20)
- [x] Authored comprehensive dark-mode Executive Assessment HTML summary (`nix_assessment_summary.html`) showcasing platform metrics, security postures, and Linux portability guides (2026-05-20)
- [x] Bootstrapped `GG-Sandboxes/james.maes` (created `main`, flipped default branch from `develop`, enabled Pages from `main /`, wrote a personal sandbox landing page with two clickable dashboard cards); both Security Alerts and AI Updates dashboards now refreshing on schedule (2026-05-20)
- [x] Second sops-managed PAT (`github-sandbox-pat`, fine-grained RW on `GG-Sandboxes/james.maes`) deployed to two Cowork project folders at `.github-deploy-pat`; refactored `home/sops/default.nix` to introduce a `mkPatDeployer` helper and migrated the existing security PAT onto it (2026-05-20)
- [x] sops-managed GitHub security PAT; pivoted from sops-nix symlink to `home.activation` script for Cowork-sandbox compatibility; registered Dark-Horse + Grogu age recipients (2026-05-19)
- [x] System maintenance pass: terragrunt+AWS perms, tmux-lock orphan fix, K8s teardown, +213 GiB disk reclaim (2026-05-13)
- [x] Audit #23 disk cleanup — caches + Kof22 build artifacts + TM snapshots; disk 95% → 71% full (2026-05-13)
- [x] Claude Code multi-domain rules cleanup + new local skills/agents/commands/templates + marketplace auto-register + pnpm + firmware/IaC perms (2026-04-27)
- [x] Switch claude-code from Homebrew cask to npm (faster release cadence) (2026-04-21)
- [x] Add firebase-cli to homebrew (2026-04-21)
- [x] Add opencode Ollama provider config (2026-04-21)
- [x] Confluence env vars added as nix session variables (2026-04-20)
- [x] Git history rewritten with filter-repo, encrypted files clean (2026-04-20)
- [x] Tmux lock PIN re-set (2026-04-20)
- [x] Tmux session naming prompt on create (2026-04-20)
- [x] Tmux set-titles for Cmd+Tab session names (2026-04-20)
- [x] ncdu alias with better defaults (2026-04-20)
- [x] Ollama (cask) + JetBrains Toolbox added (2026-04-20)
- [x] README rewritten as full environment showcase (2026-04-20)
- [x] Security hardening: git-crypt SSH/AWS/preferences, env vars for scripts (2026-04-20)
- [x] Neovim: LazyVim compat, nil_ls, ts_ls, nix treesitter (2026-04-20)
- [x] Sales-admin agent and skill added (2026-04-20)
- [x] Test F12 nested tmux toggle via SSH (2026-04-19)
- [x] Test `ls -lsrt`, `ls -la`, `ls -lS` (2026-04-19)
- [x] Test `shelp` and `shelp KEYWORD` (2026-04-19)
- [x] Test truecolor in tmux (2026-04-19, also fixed TERM override inside tmux)
- [x] Verify masApps install correctly (2026-04-19)
- [x] Audit findings resolved: 21/23 complete (2026-04-19)
- [x] Enable masApps (8 installed apps) with mas 6.0+ (2026-04-19)
- [x] Remove dual-installed delta from Nix (Homebrew wins) (2026-04-19)
- [x] Delete unused user-config.nix (2026-04-19)
- [x] Fix tmux terminal-overrides accumulation (2026-04-19)
- [x] Rolling PIN unlock for tmux lock screen (2026-04-11)
- [x] Add PR review routing rule to 3-rules.md (2026-04-08)
- [x] Fix gemini-cli brew/npm conflict (2026-04-08)
- [x] Switch run + commit + push all changes (2026-04-08)
- [x] Add opencode brew + config module with MCP servers (2026-04-08)
- [x] Add F12 nested tmux toggle for SSH (2026-04-08)
- [x] Add truecolor support to tmux + COLORTERM env var (2026-04-08)
- [x] Migrate session state from sidecar into repo (2026-04-08)
- [x] Verify session-start and session-end skills wired up (2026-04-08)
- [x] ls wrapper function: translates ls flags to eza (2026-03-13)
- [x] shelp function: comprehensive tool/alias reference (2026-03-13)
- [x] Replaced lss/lrt/llt aliases with ls-* naming convention (2026-03-13)
- [x] Disabled eza auto-aliases, defined ll/la/tree manually (2026-03-13)
- [x] Sync all brew formulae/casks with local installs (2026-03-13)
- [x] Extract homebrew config to modules/homebrew.nix (2026-03-13)
- [x] Migrate Nix packages to Homebrew (2026-03-13)
- [x] Create home/python/default.nix for pipx/pip3 (2026-03-13)
- [x] Set node@22 as default, install v25 + v20 (2026-03-13)
- [x] Add recommended packages (stern, kubectx, dust, etc.) (2026-03-13)
- [x] Add fzf shell integration (2026-03-13)
- [x] Add oh-my-zsh plugins (aws, helm, terraform, fzf, aliases) (2026-03-13)
- [x] Manage Claude Code plugins via Nix (2026-03-13)
- [x] Fix Neovim 0.11 treesitter compatibility (2026-01-05)

---

## Backlog: Tmux Performance

- [x] Investigate flickering/lag after 10min (2026-04-21, resolved)
- [x] Test with simpler status bar (2026-04-21, resolved)
- [x] Test with screensaver disabled (2026-04-21, resolved)

---

## Backlog: Linux Support

**Status:** Planned | **Priority:** Medium

Add Linux support (Ubuntu, Debian, Fedora). Home Manager modules are mostly portable; main work is creating Linux flake wrapper.

---

## Backlog: Maintenance

- [ ] Periodically update flake inputs (`nix flake update`)
- [ ] Review and remove unused packages
- [ ] Test bootstrap script on fresh macOS install
- [x] Fix masApps reinstall-on-every-run issue (2026-04-19, enabled with mas 6.0+)

---

## Backlog: Security

- [x] Add age encryption (2026-03-13, installed via brew)
- [x] Add sops for secrets management (2026-03-13, installed via brew)
- [x] Add GPG configuration module enhancements (2026-04-21, module exists)
- [x] Enhance SSH configuration (2026-04-21, module exists)

---

## Notes

- Items organized by priority
- See `./docs/FUTURE-IDEAS.md` for enhancement ideas
