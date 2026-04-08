# TODO

Active tasks and future improvements for the Nix configuration.

## Active Tasks

- [ ] Run `switch` to activate ls wrapper and shelp (changes written, not applied)
- [ ] Test `ls -lsrt`, `ls -la`, `ls -lS` after switch
- [ ] Test `shelp` and `shelp KEYWORD` after switch
- [ ] Diff remote machine (100.76.144.59) brew packages against flake when online

## Recently Completed

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

- [ ] Investigate flickering/lag after 10min (see TMUX-ISSUES.md)
- [ ] Test with simpler status bar
- [ ] Test with screensaver disabled

---

## Backlog: Linux Support

**Status:** Planned | **Priority:** Medium

Add Linux support (Ubuntu, Debian, Fedora). Home Manager modules are mostly portable; main work is creating Linux flake wrapper.

---

## Backlog: Maintenance

- [ ] Periodically update flake inputs (`nix flake update`)
- [ ] Review and remove unused packages
- [ ] Test bootstrap script on fresh macOS install
- [ ] Fix masApps reinstall-on-every-run issue

---

## Backlog: Security

- [x] Add age encryption (2026-03-13, installed via brew)
- [x] Add sops for secrets management (2026-03-13, installed via brew)
- [ ] Add GPG configuration module enhancements
- [ ] Enhance SSH configuration

---

## Notes

- Items organized by priority
- See `./docs/FUTURE-IDEAS.md` for enhancement ideas
