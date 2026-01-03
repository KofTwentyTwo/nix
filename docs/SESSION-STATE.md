# Session State

Last updated: 2026-01-03

## Current State

Session complete. All changes applied and rebuilt. Ready for next session.

## Completed This Session

- Added `QQQ_SELENIUM_HEADLESS=true` env var to `home/default.nix`
- Added `Bash(mvn:*)` to Claude allowed commands
- Added `direnv` with nix-direnv integration
- Added eza aliases: `lss` (sort by size), `lrt` (oldest first), `llt` (newest first)
- User ran `sudo darwin-rebuild switch` - all changes active

## Environment Status

| Item | Status |
|------|--------|
| `QQQ_SELENIUM_HEADLESS` | Active (new terminal needed) |
| `mvn:*` allowed | Active |
| `direnv` | Installed |
| `lss`, `lrt`, `llt` | Active |

## Active Backlog

See `./docs/TODO.md` for full task list. Key items:
- Tmux performance investigation (flickering/lag after 10min)

## How to Continue

Say **"continue from last session"**. Claude reads:
1. `./docs/SESSION-STATE.md` (this file)
2. `./docs/TODO.md`
3. `./CLAUDE.md`

**Never use `~/.claude/session-state.md`** - state is local to this repo.
