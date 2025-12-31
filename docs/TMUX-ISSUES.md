# Tmux Performance Issues

## Status: Under Investigation

Tmux auto-start disabled in WezTerm due to performance problems.

## Symptoms

- Flickering display after ~10 minutes of use
- Severe lag/slowdown in terminal responsiveness
- Issue occurs consistently after extended use

## Current Configuration

- **Status bar**: 2-line hacker aesthetic with 5-second refresh
- **Screensaver**: cmatrix triggered after 15min idle via `lock-command`
- **Touch ID**: Enabled via pam-reattach

## Potential Causes to Investigate

1. **Status bar refresh rate** - Currently 5 seconds, may be too aggressive
2. **Screensaver idle detection** - Lock hook polling overhead
3. **History buffer** - Large scrollback buffer consuming memory
4. **WezTerm + tmux interaction** - Terminal escape sequence handling
5. **cmatrix process** - May not be cleaning up properly

## Files to Review

- `home/tmux/default.nix` - Main tmux configuration
- `home/wez/config/wezterm.lua` - WezTerm settings (line 22-23 has disabled tmux)

## Workaround

WezTerm now launches zsh directly. Run `tmux` manually if needed for testing.

## Re-enable Instructions

In `home/wez/config/wezterm.lua`, uncomment line 23:
```lua
config.default_prog = { "/opt/homebrew/bin/tmux", "new-session" }
```
