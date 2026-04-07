# Tmux Performance Issues

## Status: Fix Applied, Testing

Tmux auto-start disabled in WezTerm. Config fix applied, needs manual testing.

## Root Cause

`status-interval` was set to `1` (every second), causing 60 redraws/minute of a 2-line status bar. Combined with WezTerm's rendering pipeline, this caused progressive lag after ~10 minutes.

## Fix Applied

- Changed `status-interval` from `1` to `5`
- Removed seconds from clock display (`%H:%M` instead of `%H:%M:%S`)
- Shell commands in status bar were already removed in a prior fix

## Testing

1. Run `tmux` manually in WezTerm
2. Use for 15+ minutes with normal workflow
3. Watch for flickering or lag
4. If stable, re-enable auto-start in `home/wez/config/wezterm.lua` (line 23)

## Re-enable Auto-Start

In `home/wez/config/wezterm.lua`, uncomment:
```lua
config.default_prog = { "/opt/homebrew/bin/tmux", "new-session" }
```
