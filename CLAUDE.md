# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Session Continuity

Say **"continue from last session"** to resume. Read these files first:
- `./docs/SESSION-STATE.md` - Current context and status
- `./docs/TODO.md` - Active tasks and progress
- `./CLAUDE.md` - This file (project context)

**Never use `~/.claude/session-state.md`** - always use local `./docs/` files for state.

## Planning Mode

Before any sizable task, create a plan:
1. Create `./docs/PLAN-<task-name>.md` with goal, approach, files affected, steps
2. Update `./docs/TODO.md` with task breakdown
3. Get user approval before implementing

Periodically update `./docs/SESSION-STATE.md` and `./docs/TODO.md` as you work.

## Commands

```bash
# Build and activate (requires sudo)
sudo darwin-rebuild switch --flake ~/.config/nix

# Dry-run / check
darwin-rebuild check --flake ~/.config/nix

# Update flake inputs
nix flake update

# Unlock encrypted files (after fresh clone)
git-crypt unlock

# Kill tmux (required after tmux config changes)
tmux kill-server
```

## Architecture

**nix-darwin + Home Manager** for macOS (Apple Silicon). Single flake manages system and user environment.

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point: nix-darwin, Home Manager, machines, PAM/Touch ID |
| `home/default.nix` | Imports all Home Manager modules |
| `home/*/default.nix` | Self-contained modules (one concern each) |

### Key Modules

| Module | Purpose |
|--------|---------|
| `ai/` | AI config files (`~/.ai/*`) - rules, preferences, profile |
| `claude/` | MCP servers, permissions, settings |
| `wez/` | WezTerm with hacker status bar |
| `tmux/` | Screensaver, status bar (currently disabled) |
| `scripts/` | Custom git commands (`ghelp`, `gclo`, etc.) |
| `zsh/` | Shell config with SSH host tracking |

### Patterns

- **Packages**: Homebrew in `flake.nix`, Nix in `home/default.nix`
- **New modules**: Create `home/foo/default.nix`, import in `home/default.nix`
- **File generation**: `home.file."path".text` or `.source`
- **Secrets**: git-crypt encrypted

## AI Rules (`home/ai/3-rules.md`)

Key rules that govern Claude behavior:

| Rule | Summary |
|------|---------|
| **Test-first commits** | Never commit until all tests pass locally (100%) |
| **Planning mode** | Create PLAN docs before sizable tasks |
| **Session continuity** | Periodically update docs/SESSION-STATE.md and TODO.md |
| **Secrets handling** | Never log/commit credentials |
| **Retry limits** | Max 2-3 retries before asking user |
| **Pause on failure** | Stop, summarize, confirm before fixing |
| **Change direction** | Summarize what/why and confirm before pivoting |

## MCP Servers

| Server | Purpose |
|--------|---------|
| `github` | GitHub API |
| `qqq-mcp` | Local QQQ at localhost:8080/mcp |
| `circleci-mcp-server` | CircleCI integration |
| `atlassian` | Jira/Confluence |

## Known Issues

**Tmux**: Auto-start disabled due to flickering/lag after 10min. See `./docs/TMUX-ISSUES.md`.

## Docs Directory

| File | Purpose |
|------|---------|
| `SESSION-STATE.md` | Current session context (read on resume) |
| `TODO.md` | Active tasks and backlog |
| `TMUX-ISSUES.md` | Tmux performance investigation |
| `FUTURE-IDEAS.md` | Enhancement backlog |
| `PLAN-*.md` | Task-specific plans (created as needed) |
