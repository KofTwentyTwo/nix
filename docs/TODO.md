# TODO

Active tasks and future improvements for the Nix configuration.

## Active Tasks

- [x] Add AI agent rules (secrets, retries, expensive ops, progress reporting)
- [x] Add planning mode and session continuity rules
- [x] Move TODO.md to docs/ directory
- [x] Commit rule changes
- [x] Update CLAUDE.md with full context
- [x] Push all changes
- [ ] Rebuild nix config to apply new rules (user action: `sudo darwin-rebuild switch`)

## Backlog: Tmux Performance

- [ ] Investigate flickering/lag after 10min (see TMUX-ISSUES.md)
- [ ] Test with simpler status bar
- [ ] Test with screensaver disabled

---

## Backlog: Linux Support

**Status:** Planned  
**Priority:** Medium  
**Estimated Effort:** 2-4 hours

### Description
Add Linux support to make the configuration work on Linux distributions (Ubuntu, Debian, Fedora, etc.) in addition to macOS.

### Current State
- ✅ Configuration works perfectly on macOS via nix-darwin
- ✅ Home Manager modules are mostly portable
- ❌ Linux support not implemented

### What Needs to Be Done

1. **Create Linux-compatible flake**
   - [ ] Create `flake-linux.nix` based on `flake-linux.nix.example`
   - [ ] Remove nix-darwin dependency
   - [ ] Use Home Manager standalone instead
   - [ ] Update system architecture detection

2. **Update paths for Linux**
   - [ ] Change `/Users/` → `/home/` in Home Manager modules
   - [ ] Remove `/opt/homebrew/` paths (macOS-specific)
   - [ ] Update LLVM path or use system LLVM
   - [ ] Update Python paths for Linux

3. **Remove macOS-specific configurations**
   - [ ] Conditionally exclude Homebrew config
   - [ ] Remove macOS system defaults
   - [ ] Update bootstrap script to detect OS

4. **Create Linux bootstrap script**
   - [ ] Create `bootstrap-linux.sh`
   - [ ] Detect Linux distribution
   - [ ] Use `home-manager switch` instead of `darwin-rebuild switch`

5. **Documentation**
   - [ ] Update README with Linux instructions
   - [ ] Create Linux-specific setup guide
   - [ ] Document differences between macOS and Linux

### Resources Created
- ✅ `LINUX.md` - Detailed migration guide
- ✅ `LINUX_SETUP.md` - Quick setup guide  
- ✅ `flake-linux.nix.example` - Example Linux flake

### Notes
- Home Manager modules in `home/` directory are already portable
- Main work is creating Linux flake wrapper and updating paths
- Consider using conditional includes for OS-specific settings

---

## Backlog: Quick Wins

**Status:** Optional  
**Priority:** Low  
**Estimated Effort:** 30 minutes each

### High-Value Additions
- [ ] Add `bat` - Better cat with syntax highlighting
- [ ] Add `eza` - Modern ls replacement
- [ ] Add `zoxide` - Smarter cd
- [ ] Add `delta` - Better git diff viewer
- [ ] Add `direnv` - Auto-load environment variables

See `SUGGESTIONS.md` for full list and implementation details.

---

## Backlog: Maintenance

**Status:** Ongoing  
**Priority:** Low

- [ ] Periodically update flake inputs (`nix flake update`)
- [ ] Review and remove unused packages
- [ ] Update documentation as configuration evolves
- [ ] Test bootstrap script on fresh macOS install
- [ ] Review and optimize startup time

---

## Backlog: Documentation

**Status:** Optional  
**Priority:** Low

- [ ] Add more examples to README
- [ ] Create troubleshooting guide
- [ ] Add architecture diagrams
- [ ] Document all available modules
- [ ] Create video walkthrough

---

## Backlog: Security

**Status:** Optional  
**Priority:** Medium

- [ ] Add GPG configuration module
- [ ] Enhance SSH configuration
- [ ] Add age/sops for additional secrets management
- [ ] Review and harden security settings

---

## Backlog: Config Enhancements

**Status:** Optional  
**Priority:** Low

- [ ] Add more Home Manager program modules (see SUGGESTIONS.md)
- [ ] Create utility scripts (update, backup, health-check)
- [ ] Add Neovim plugin management via Nix (optional)
- [ ] Consider using devenv or nix-shell for project environments

---

## Notes

- Items are organized by priority and effort
- Check off items as they're completed
- Add new items as needed
- Update status and priority as work progresses

