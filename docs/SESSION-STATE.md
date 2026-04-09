# Session State

**Last Updated:** 2026-04-08

## Current Status
Three local changes (opencode, tmux, truecolor) need `switch` to activate, then commit+push.

## What Was Done This Session
- Migrated session state from ClaudeCode sidecar into repo `docs/`
- Updated `.gitignore` to allow state files, merged CLAUDE.md with sidecar version
- Verified session-start and session-end skills are wired up
- Added opencode to brews + created `home/opencode/default.nix` module
- Fixed opencode MCP config format (type=local, command=array, environment=object)
- Added F12 nested tmux toggle (disables local prefix, dims status bar, REMOTE indicator)
- Added truecolor support: RGB capability in tmux terminal-overrides, COLORTERM=truecolor, allow-passthrough
- Pulled remote changes (codex, gemini-cli, slack-cli modules from other machine)

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | 3 uncommitted files, up to date with origin |

## Pending Work
- [ ] Run `sudo darwin-rebuild switch --flake ~/.config/nix` to activate all changes
- [ ] Test opencode launches without config errors
- [ ] Test F12 nested tmux toggle via SSH
- [ ] Test truecolor in tmux (apps should stop showing 256-color warning)
- [ ] Commit and push local changes
- [ ] Set tmux lock PIN (`tmux-lock-set-pin.sh`)
- [ ] Work through audit findings (`docs/AUDIT-2026-04-07.md`)

## Key Reference
- OpenCode MCP schema: type=`local` (not stdio), command=array, environment=object (not env)
- Truecolor requires: `:RGB` in terminal-overrides + `COLORTERM=truecolor` + `allow-passthrough on`
- Sidecar archive (read-only): `/Users/james.maes/Git.Local/kof22/ClaudeCode/nix/`
