# Session State

Last updated: 2025-12-31

## Current State

Tmux auto-start **disabled** due to performance issues (flickering/lag after 10min). WezTerm launches zsh directly. All tmux configuration preserved in `home/tmux/default.nix` for future debugging.

## Active Issue

**Tmux Performance** - See `./docs/TMUX-ISSUES.md` for details and investigation plan.

## Recent Completions

- Tmux module: screensaver (cmatrix at 15min), hacker status bar
- WezTerm: configured (tmux auto-start now disabled)
- Touch ID in tmux via pam-reattach
- Claude module: MCP servers, permissions, settings management
- Documentation: CLAUDE.md updated with full architecture

## Next Steps When Resuming

1. Investigate tmux performance issues (see TMUX-ISSUES.md)
2. Consider alternative approaches: simpler status bar, disable screensaver, test in isolation

## Future Ideas (Not Started)

See `./docs/FUTURE-IDEAS.md` for enhancement backlog.

## How to Continue

Say **"continue from last session"**. Claude reads this file and `CLAUDE.md` for context.
