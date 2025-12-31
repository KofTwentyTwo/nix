# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Session Continuity

Say **"continue from last session"** to resume. Check `./docs/SESSION-STATE.md` for context.

## Commands

```bash
# Build and activate configuration
darwin-rebuild switch --flake ~/.config/nix

# Kill tmux server (required after config changes to reload)
tmux kill-server

# Full rebuild with tmux reload
darwin-rebuild switch --flake ~/.config/nix && tmux kill-server

# Dry-run / check configuration
darwin-rebuild check --flake ~/.config/nix

# Update flake inputs
nix flake update

# Unlock encrypted files (required after fresh clone)
git-crypt unlock
```

## Architecture

**nix-darwin + Home Manager** configuration for macOS (Apple Silicon). Single flake manages system and user environment.

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point: userConfig, nix-darwin, Home Manager, machines (Darth/Grogu/Renova), PAM/Touch ID |
| `home/default.nix` | Imports all Home Manager modules |
| `home/*/default.nix` | Self-contained modules (one concern each) |

### Home Manager Modules

| Module | Purpose |
|--------|---------|
| `1password/` | SSH agent, `op-load-secrets` function |
| `ai/` | AI config files (`~/.ai/*`) |
| `claude/` | MCP servers, permissions, settings (see below) |
| `tmux/` | Screensaver (cmatrix), hacker status bar |
| `wez/` | WezTerm terminal emulator |
| `starship/` | Prompt theme (green borders, nerd fonts) |
| `scripts/` | Custom shell scripts (`ghelp`, `gclo`, etc.) |
| `zsh/`, `ohmyzsh/` | Shell configuration |
| Others | `aws/`, `ca-certs/`, `gpg/`, `k9s/`, `nvim/`, `ssh/`, `updates/` |

### Key Patterns

- **Packages**: Homebrew in `flake.nix`, Nix in `home/default.nix`
- **New modules**: Create `home/foo/default.nix`, import in `home/default.nix`
- **File generation**: `home.file."path".text` or `.source`
- **Tmux changes**: Require `tmux kill-server` to reload
- **Secrets**: git-crypt encrypted, run `git-crypt unlock` after clone

## Claude Module (`home/claude/default.nix`)

Manages Claude Code configuration with activation scripts that merge settings (preserves user data).

### MCP Servers

| Server | Type | Purpose |
|--------|------|---------|
| `github` | stdio | GitHub API via `@modelcontextprotocol/server-github` |
| `qqq-mcp` | http | Local QQQ server at `localhost:8080/mcp` |
| `circleci-mcp-server` | stdio | CircleCI via `@circleci/mcp-server-circleci` |
| `atlassian` | sse | Jira/Confluence at `mcp.atlassian.com` |

### Permissions

Pre-approved commands in `permissions.allow[]`:
- File ops: `ls`, `cat`, `grep`, `rg`, `find`, `fd`
- Git read-only: `status`, `diff`, `log`, `branch`, `show`
- Build tools: `mvn`, `npm`, `cargo`, `python`, `nix`
- MCP read-only: Atlassian, CircleCI, GitHub queries

### Settings

- `~/.claude.json`: MCP servers config
- `~/.claude/settings.json`: User prefs (theme: dark, terminalBellOnPrompt: true)
- `~/.claude/settings.local.json`: Permissions (merged, not overwritten)
- `~/.claude/CLAUDE.md`: Global context (profile, rules, preferences)

**Note:** Session state is per-project, not global. Each repo has its own `./docs/SESSION-STATE.md`.

## Tmux Setup (`home/tmux/default.nix`)

**STATUS: DISABLED** - Auto-start disabled due to performance issues (flickering/lag after 10min). Config preserved for future debugging.

- **Screensaver**: cmatrix at 15min idle
- **Status bar**: Two-line hacker aesthetic (green/yellow/purple/cyan)
- **Touch ID**: Works via pam-reattach

### Known Issue
Tmux experiences flickering and severe lag after ~10 minutes of use. See `./docs/TMUX-ISSUES.md` for investigation notes.

### Constraints (do not violate)
- No mouse/clipboard/keybinding changes in tmux
- Keep config minimal beyond screensaver and status bar
