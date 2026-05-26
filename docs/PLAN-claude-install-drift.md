# Claude install-channel drift diagnosis (2026-05-26)

## Symptom

Starting `claude` shows the first-launch setup wizard ("set your colors and then login") despite a working Nix-managed config. Every fix attempt reverts; a non-Nix process keeps recreating `/opt/homebrew/bin/claude` as a root-owned symlink into a root-owned `/opt/homebrew/lib/node_modules/@anthropic-ai/` package dir.

## Root causes (confirmed)

1. **`~/.claude.json` was repeatedly clobbered as root**, wiping the `oauthAccount` and reducing the file to `closedIssuesLastChecked` + `metricsStatusCache` keys. Backups in `~/.claude/backups/` are all post-corruption — OAuth tokens are not recoverable from disk.
2. **Three competing claude binaries existed at different times**:
   - `~/.local/bin/claude` (native install, the canonical/desired one)
   - `~/.npm-global/bin/claude` (user-owned npm-channel)
   - `/opt/homebrew/bin/claude` (root-owned, points into root-owned `@anthropic-ai/` under brew's prefix)
   `installMethod: "global"` in `~/.claude.json` confirms claude was running from the npm-channel install.
3. **Commit `a93b80f`'s eviction logic in `bootstrapClaude` is the wrong layer.** The native installer (`curl claude.ai/install.sh | bash`) fails silently when invoked from inside the home-manager activation context (`[claude] WARN install failed (offline?); continuing`). Running the same install.sh from a normal user shell works fine. Net effect: activation evicts the strays, install step trips, the box ends up with no `claude` binary at all.

## Root causes (unconfirmed — what we couldn't pin)

What process keeps writing `/opt/homebrew/lib/node_modules/@anthropic-ai/` as root with a matching `/opt/homebrew/bin/claude` symlink. Notes:
- The `claude` brew formula is the **desktop app cask** (`Claude.app` only) — its artifact list does NOT include `/opt/homebrew/bin/claude`.
- `/opt/homebrew/lib/node_modules/` is user-owned, so an `npm install -g` against brew's node prefix would land user-owned by default. The fact the children are root-owned means whoever wrote them ran with `sudo` despite not needing to.
- Claude desktop app maintains its own `~/Library/Application Support/Claude/claude-code/` and `claude-code-vm/` dirs (version 2.1.149 currently) — likely unrelated to the `/opt/homebrew/bin/claude` install (which was 2.1.150).
- Live `fs_usage` watching `/opt/homebrew/lib/node_modules/@anthropic-ai/` for 4 minutes after eviction caught nothing — the recreate isn't on a fixed timer.
- Previous recreate events at 16:36 and 16:42 may correlate with `darwin-rebuild switch` runs but this is unproven.

## Current state (pre-reboot, 16:54)

| Thing | State |
|---|---|
| `/opt/homebrew/bin/claude` | GONE |
| `~/.local/bin/claude` | GONE |
| `~/.npm-global/bin/claude` | GONE |
| `/opt/homebrew/lib/node_modules/@anthropic-ai/` | GONE |
| `~/.claude.json` | 724 bytes, **user-owned now**, missing OAuth (re-login required) |
| `~/.claude/settings.json` | INTACT (30 plugins, 4 MCP servers, theme) |
| `~/.claude/settings.local.json` | INTACT (400 allow rules) |
| `home/claude/default.nix` | **Uncommitted** — eviction logic reverted; back to "install if missing" |
| `.claude/settings.local.json` (in nix repo) | **Uncommitted** — accumulated cleanup permissions from session |

## Nix-side change (uncommitted)

`home/claude/default.nix:bootstrapClaude` — removed the stray-install eviction loops. Now matches the historical "install if missing, manage config, ensure ownership" responsibility. **The eviction was the cause of the silent install-failure state we got into.** Cleanup is a manual concern, not an activation concern.

Decision recorded in memory: `feedback-claude-script-no-cleanup`.

## Post-reboot recovery steps

```bash
# 1. Get a native claude installed as your user, outside any activation context
/usr/bin/curl -fsSL https://claude.ai/install.sh | /bin/bash
which claude   # expect ~/.local/bin/claude

# 2. Apply the home/claude/default.nix revert so future rebuilds don't re-trigger the
#    eviction-then-failed-install pattern. (If you want to review the diff first:
#    `git diff home/claude/default.nix`)
sudo darwin-rebuild switch --flake ~/.config/nix

# 3. Verify claude is intact
which claude                                       # ~/.local/bin/claude
ls -la ~/.claude.json                              # owned by james.maes
jq '.mcpServers | keys' ~/.claude.json             # qqq-mcp, circleci-mcp-server, ruflo

# 4. Start a fresh claude session
claude
# Expect setup wizard (colors, login) the first time. Login uses the keychain
# token if it's still there from prior sessions — usually a one-click confirm.

# 5. Verify settings load: plugins, MCP servers, permissions should all be present
#    (these come from ~/.claude/settings.json which has been intact the whole time)
```

## If `/opt/homebrew/bin/claude` reappears post-reboot

The migrator is still alive. To catch it on the next attempt, prep this in another terminal BEFORE provoking it:

```bash
# Long-running watcher
sudo /usr/sbin/fs_usage -w -f filesys 2>&1 \
  | rg --line-buffered "anthropic-ai|@anthropic-ai" \
  | tee /tmp/claude-fs-trace.log
```

Then run whatever you suspect triggers it (rebuild, launch Claude.app, etc.). Watch `/tmp/claude-fs-trace.log` for the writer process PID + name. Cross-reference with `ps -p <pid> -o pid,ppid,user,command` while it's still running, or in the unified log: `log show --predicate 'processIdentifier == <pid>' --last 5m`.

## What we should change in the Nix repo (open question)

If the migrator stays dormant, no further action needed — the revert is enough.

If it returns, options:
- Add an `activation.evictStrayClaudes` script back, BUT only after fixing the native-installer-fails-in-activation problem (or accept that the script does cleanup-only with no install attempt, and a separate shell hook handles install).
- Set `installMethod: "native"` in `~/.claude.json` declaratively (would need to check if claude respects this hint to suppress its own migrator).
- Investigate whether Claude.app's `[CCD]` PATH-floor logic spawns helpers that do the install — found references but no smoking-gun call site in 5 min of search.
