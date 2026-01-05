# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Session Continuity

Say **"continue from last session"** to resume. Read these files first:
- `./docs/SESSION-STATE.md` - Current context and status
- `./docs/TODO.md` - Active tasks and progress
- `./CLAUDE.md` - This file (project context)

**Never use `~/.claude/session-state.md`** - always use local `./docs/` files for state.

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
```

## Architecture

**nix-darwin + Home Manager** for macOS (Apple Silicon). Single flake manages system and user environment.

### Core Files

| File | Purpose |
|------|---------|
| `flake.nix` | Entry point: nix-darwin, Home Manager, machines, PAM/Touch ID |
| `home/default.nix` | Imports modules, env vars (`QQQ_SELENIUM_HEADLESS`), programs |
| `home/*/default.nix` | Self-contained modules (one concern each) |

### Key Modules

| Module | Purpose |
|--------|---------|
| `ai/` | AI config files (`~/.ai/*`) - rules, preferences, profile |
| `claude/` | MCP servers, permissions, settings |
| `nvim/` | Neovim + LazyVim (config in `nvim/config/`) |
| `wez/` | WezTerm with status bar |
| `zsh/` | Shell config, aliases (`lss`, `lrt`, `llt`), SSH tracking |
| `scripts/` | Custom git commands (`ghelp`, `gclo`, etc.) |

### Installed Tools

| Tool | Alias | Purpose |
|------|-------|---------|
| `bat` | `cat` | Syntax-highlighted cat |
| `eza` | `ls`, `ll`, `la`, `lss`, `lrt`, `llt` | Modern ls |
| `zoxide` | `z` | Smart cd |
| `delta` | — | Git diff viewer |
| `direnv` | — | Auto-load `.envrc` files |

### Patterns

- **Packages**: Homebrew in `flake.nix`, Nix in `home/default.nix`
- **New modules**: Create `home/foo/default.nix`, import in `home/default.nix`
- **Env vars**: Add to `home.sessionVariables` in `home/default.nix`
- **Aliases**: Add to `shellAliases` in `home/zsh/default.nix`
- **Secrets**: git-crypt encrypted

## AI Rules (`home/ai/3-rules.md`)

| Rule | Summary |
|------|---------|
| **Planning mode** | Create `./docs/PLAN-*.md` before sizable tasks |
| **Session continuity** | Update `./docs/SESSION-STATE.md` and `TODO.md` periodically |
| **Allowed commands** | `mvn:*` and many others run without asking |
| **Secrets handling** | Never log/commit credentials |
| **Pause on failure** | Stop, summarize, confirm before fixing |

## MCP Servers

| Server | Purpose |
|--------|---------|
| `github` | GitHub API |
| `qqq-mcp` | Local QQQ at localhost:8080/mcp |
| `circleci-mcp-server` | CircleCI integration |
| `atlassian` | Jira/Confluence |

## Known Issues

**Tmux**: Auto-start disabled due to flickering/lag. See `./docs/TMUX-ISSUES.md`.

**Neovim**: `lazy-lock.json` is NOT version controlled (deleted intentionally). Lazy.nvim manages plugin versions at runtime. After Neovim updates, may need to clear cache: `rm -rf ~/.local/share/nvim/lazy ~/.cache/nvim`

## Docs Directory

| File | Purpose |
|------|---------|
| `SESSION-STATE.md` | Current session context (read on resume) |
| `TODO.md` | Active tasks and backlog |
| `TMUX-ISSUES.md` | Tmux performance investigation |
| `PLAN-*.md` | Task-specific plans (created as needed) |
