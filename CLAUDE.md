# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Session Continuity

Say **"continue from last session"** to resume. Read these files first:
- `./docs/SESSION-STATE.md` - Current context and status
- `./docs/TODO.md` - Active tasks and progress
- `./CLAUDE.md` - This file (project context)

**Never use `~/.claude/session-state.md`** - always use local `./docs/` files for state.

## Learnings Ingestion

On session start in this repo (or when the user says "process learnings"):

1. Read each `.md` in `learnings_to_process/` (oldest first by epoch in filename).
2. Integrate each into the right home:
   - Preferences / identity / role → `home/ai/1-profile.md`
   - Behavioral mandates (MUST / SHOULD) → `home/ai/3-rules.md`
   - Operational ground truth / current setup → `home/ai/5-learnings.md`
   - Project-specific facts about this repo → this `CLAUDE.md`
   - Per-project memory → `~/.claude/projects/<sanitized-cwd>/memory/`
   - Permissions / hooks / MCP servers → `~/.claude/settings.json` or `home/claude/default.nix`
3. **Quality bar** — integrate only if the learning is durable, non-contradictory, non-duplicate, and concise. If a learning conflicts with an existing rule, surface it to the user — do NOT overwrite silently.
4. Move processed files to `learnings_to_process/processed/<epoch>.md`. Leave malformed or contradictory files in place and report them.

Goal: faster, better future sessions — not a wall of guidance text. If integrating a learning would bloat the target file, condense before adding.

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
| `modules/homebrew.nix` | All brew formulae (137) and casks (47) |
| `home/default.nix` | Imports modules, env vars, programs (bat, eza, zoxide, fzf, direnv) |
| `home/*/default.nix` | Self-contained modules (one concern each) |

### Key Modules

| Module | Purpose |
|--------|---------|
| `ai/` | AI config files (`~/.ai/*`) - rules, preferences, profile |
| `claude/` | MCP servers, permissions, settings, plugins |
| `nvim/` | Neovim + LazyVim (config in `nvim/config/`) |
| `wez/` | WezTerm with status bar |
| `zsh/` | Shell config, ls wrapper, shelp, aliases, SSH tracking |
| `scripts/` | Custom git commands (`ghelp`, `gclo`, etc.) |
| `ohmyzsh/` | Oh-My-Zsh plugins (git, sudo, docker, kubectl, aws, helm, terraform, fzf, aliases) |

### Eza/ls Setup (Important)

`programs.eza.enableZshIntegration = false` in home/default.nix. Eza's auto-aliases are disabled because zsh aliases expand before function lookup, which breaks the ls wrapper function. All eza aliases (`ll`, `la`, `tree`, `ls-*`) are defined manually in home/zsh/default.nix.

The `ls()` wrapper function in zsh initContent translates standard ls flags to eza:
- `-t` becomes `--sort=modified`
- `-S` becomes `--sort=size`
- `-s` becomes `-S` (blocksize)
- `-h` is skipped (eza default)
- Everything else passes through

### Installed Tools

| Tool | Alias | Purpose |
|------|-------|---------|
| `bat` | `cat` | Syntax-highlighted cat |
| `eza` | `ls` (wrapper), `ll`, `la`, `tree`, `ls-*` | Modern ls |
| `zoxide` | `z` | Smart cd |
| `delta` | -- | Git diff viewer |
| `direnv` | -- | Auto-load `.envrc` files |
| `shelp` | -- | Help reference for all tools/aliases/scripts |

### Patterns

- **Packages**: Homebrew in `modules/homebrew.nix`, Nix in `home/default.nix`
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

**Neovim**: `lazy-lock.json` is NOT version controlled. After updates, may need: `rm -rf ~/.local/share/nvim/lazy ~/.cache/nvim`

## Docs Directory

| File | Purpose |
|------|---------|
| `SESSION-STATE.md` | Current session context (read on resume) |
| `TODO.md` | Active tasks and backlog |
| `TMUX-ISSUES.md` | Tmux performance investigation |
| `FUTURE-IDEAS.md` | Enhancement ideas |
| `AUDIT-2026-04-07.md` | Configuration audit with 23 findings |
| `PLAN-*.md` | Task-specific plans (created as needed) |
