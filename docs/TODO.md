# TODO

Active tasks and future improvements for the Nix configuration.

## Active Tasks

- [ ] On Darth: verify `age-keygen -y ~/.config/sops/age/keys.txt` matches the `&darth` pubkey in `.sops.yaml`; pull + rebuild
- [ ] On Renova: generate age key, share pubkey, add `&renova` to `.sops.yaml`, `sops updatekeys secrets/github-security-pat.enc`, pull + rebuild
- [ ] On Darth (after Renova pubkey added): `sops updatekeys secrets/aws-credentials.enc` and uncomment the `secrets."aws-credentials"` block in `home/sops/default.nix`
- [ ] Commit the 25 staged changes from 2026-04-27 Claude Code cleanup session and push to origin
- [ ] After push, sync Darth / Renova: `git pull && sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)`
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

## Recently Completed

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
