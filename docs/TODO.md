# TODO

Active tasks and future improvements for the Nix configuration.

## Active Tasks

None - all current tasks complete.

## Recently Completed

- [x] Fix Neovim 0.11 treesitter compatibility (2026-01-05)
- [x] Remove `lazy-lock.json` from version control
- [x] Remove unsupported treesitter parsers
- [x] Add `QQQ_SELENIUM_HEADLESS=true` env var
- [x] Add `mvn:*` to Claude allowed commands
- [x] Add `direnv` with nix-direnv integration
- [x] Add eza aliases (`lss`, `lrt`, `llt`)

---

## Backlog: Tmux Performance

- [ ] Investigate flickering/lag after 10min (see TMUX-ISSUES.md)
- [ ] Test with simpler status bar
- [ ] Test with screensaver disabled

---

## Backlog: Linux Support

**Status:** Planned | **Priority:** Medium

Add Linux support (Ubuntu, Debian, Fedora). Home Manager modules are mostly portable; main work is creating Linux flake wrapper.

Resources: `LINUX.md`, `LINUX_SETUP.md`, `flake-linux.nix.example`

---

## Backlog: Quick Wins

**Status:** Mostly complete

| Tool | Status |
|------|--------|
| `bat` | Installed, `cat` aliased |
| `eza` | Installed, `ls` aliased, custom aliases added |
| `zoxide` | Installed |
| `delta` | Installed, git configured |
| `direnv` | Installed |

---

## Backlog: Maintenance

- [ ] Periodically update flake inputs (`nix flake update`)
- [ ] Review and remove unused packages
- [ ] Test bootstrap script on fresh macOS install

---

## Backlog: Security

- [ ] Add GPG configuration module
- [ ] Enhance SSH configuration
- [ ] Add age/sops for secrets management

---

## Notes

- Items organized by priority
- Check off items as completed
- See `./docs/FUTURE-IDEAS.md` for enhancement ideas
