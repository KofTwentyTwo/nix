# Session State

**Last Updated:** 2026-04-09

## Current Status
Repo is clean and fully synced with origin. All prior session changes are committed and pushed.

## What Was Done This Session
- Committed local changes (git fetch permission, session state update)
- Resolved merge conflict in SESSION-STATE.md (took remote's more complete version)
- Merged origin/main into local main (pull had rebase issues, used `--no-rebase`)
- Added `git fetch` and `git pull` to Claude auto-allowed commands
- Pushed all commits to origin — repo clean, up to date

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Clean, up to date with origin |

## Pending Work
- [ ] Run `sudo darwin-rebuild switch --flake ~/.config/nix` to activate all changes
- [ ] Test opencode launches without config errors
- [ ] Test F12 nested tmux toggle via SSH
- [ ] Test truecolor in tmux (apps should stop showing 256-color warning)
- [ ] Set tmux lock PIN (`tmux-lock-set-pin.sh`)
- [ ] Work through audit findings (`docs/AUDIT-2026-04-07.md`)

## Key Reference
- OpenCode MCP schema: type=`local` (not stdio), command=array, environment=object (not env)
- Truecolor requires: `:RGB` in terminal-overrides + `COLORTERM=truecolor` + `allow-passthrough on`
- Sidecar archive (read-only): `/Users/james.maes/Git.Local/kof22/ClaudeCode/nix/`
