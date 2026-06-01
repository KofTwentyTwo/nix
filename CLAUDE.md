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
- **Secrets**:
  - Sensitive config (SSH topology, AI prefs, etc.) → git-crypt (see `.gitattributes`)
  - Credentials / tokens → sops-nix (`secrets/*.enc`). Age key at `~/.config/sops/age/keys.txt`; per-machine pubkeys + creation rules in `.sops.yaml`. Declarations live in `home/sops/default.nix`. Add a new secret: encrypt with `sops -e --filename-override secrets/foo.enc --input-type binary --output-type binary <plaintext> > secrets/foo.enc`, declare it in `home/sops/default.nix`, `git add` (flakes only see tracked files), rebuild. Add a new machine: `age-keygen -y` its pubkey, append to `.sops.yaml`, `sops updatekeys secrets/*.enc` on any host that can already decrypt.
  - **Sandboxed-consumer exception** (e.g. Claude Cowork scheduled tasks): the sandbox only mounts specific paths (the project folder + `~/Git.Local/dmd`); sops-nix's default symlink-into-`~/.config/sops-nix/` dangles inside the sandbox. For these, bypass sops-nix's `secrets.*` block and use the `mkPatDeployer { name, encFile, destinations }` helper in `home/sops/default.nix` — it emits a `home.activation` entry that `sops --decrypt`s to regular files at every path in `destinations` (mode 0600, atomic mv via mktemp). Both `github-security-pat` and `github-sandbox-pat` use this; see those activation entries as examples. To add a new sandboxed consumer for an existing PAT, just append its `.github-pat`/`.github-deploy-pat` path to the `destinations` list — missing folders are skipped per-destination.

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
| `ruflo` | Multi-agent orchestration (swarms, hive-mind, persistent memory). CLI installed via `home/npm-globals`. |

## Skills & Plugins

Skills come from two mechanisms (see `home/claude/skills.nix` and `home/codex/default.nix`):
- **Symlinked skills** — flake inputs pinned in `flake.lock`, symlinked into `~/.claude/skills/` (namespaced `ns--name`) and `~/.codex/skills/` (plain names). This is how Codex gets the mattpocock/anthropic skill sets. (Codex ≥0.135.0 *also* has its own plugin system + a Claude-plugin compat layer that can load `claude-plugins-official` marketplace plugins, but those are Codex/user-managed in `~/.codex/config.toml`, not seeded by Nix — see the security-guidance Stop hook note under Known Issues.)
- **Claude plugins** — `enabledPlugins` + the `installClaudePluginMarketplaces` activation in `home/claude/default.nix` reproduce `claude plugin marketplace add` / `claude plugin install` declaratively.

Operational notes:
- **mattpocock engineering skills**: run `/setup-matt-pocock-skills` (Claude) once per repo before using `triage` / `to-issues` / `to-prd` / `tdd` / `diagnose` / `improve-codebase-architecture` / `zoom-out` — it scaffolds the repo's issue tracker, triage labels, and domain docs that those skills read.
- **`product-management@knowledge-work-plugins`** (Anthropic): installed as a full Claude plugin (8 PM skills + `/brainstorm` + 16 HTTP MCP servers). Its `.mcp.json` registers its own `atlassian` and `figma` servers that **overlap** the official-marketplace plugins → expect duplicate MCP servers and possible first-use OAuth prompts. No per-server opt-out; disable the whole plugin or leave the unused ones idle (HTTP MCPs are silent until invoked). The same 8 PM skills are mirrored into Codex as plain symlinks.
- **Marketplace activation** forces HTTPS for clones (`GIT_CONFIG_* insteadOf`) so it works in the keyless `sudo` activation context on fresh machines.

## Known Issues

**Tmux**: Auto-start disabled due to flickering/lag. See `./docs/TMUX-ISSUES.md`.

**Neovim**: `lazy-lock.json` is NOT version controlled. After updates, may need: `rm -rf ~/.local/share/nvim/lazy ~/.cache/nvim`

**sops `aws-credentials`**: `secrets/aws-credentials.enc` is encrypted only to the `&darth` age key. The declaration in `home/sops/default.nix` is commented out because `sops-install-secrets` is fail-fast — leaving it active would block every other sops-managed secret on non-Darth hosts. To restore: on Darth, after the other machines' pubkeys are in `.sops.yaml`, run `sops updatekeys secrets/aws-credentials.enc`, commit, then uncomment the block. Until then, AWS credentials need to come from elsewhere (1Password, aws-vault, etc.) on non-Darth hosts.

**Codex + security-guidance Stop hook**: Codex 0.135.0's Claude-plugin compat layer maps `security-guidance@claude-plugins-official`'s `Stop` hook into a Codex stop hook. The hook's `emit_metrics()` always prints Claude's `{"metrics":…}` (`SyncHookJSONOutput`) — even on the disabled path — which Codex rejects: *"hook returned invalid stop hook JSON output."* `ENABLE_STOP_REVIEW=0` / `SECURITY_GUIDANCE_DISABLE=1` don't fix it. Fix: `home/codex/default.nix` has a `disableCodexSgStopHook` activation that idempotently sets `enabled = false` on the `[hooks.state."security-guidance@…:stop:*"]` entry in `~/.codex/config.toml` (per-hook disable; edit-time pattern warnings stay on). Caveat: `config.toml` is Codex-owned — if Codex rewrites `hooks.state` on a trust event it may drop the flag until the next `darwin-rebuild switch` re-applies it. The plugin enablement itself is Codex/user drift, not Nix-seeded.

**sops deferred machines**: `.sops.yaml` lists Darth + Dark-Horse + Grogu age recipients. Renova is not yet added (no key collected); the `&darth` pubkey is also unconfirmed against the actual Darth host. Add them by collecting `age-keygen -y ~/.config/sops/age/keys.txt` output on each, appending to `.sops.yaml`, and running `sops updatekeys` on each `secrets/*.enc` from a host that can already decrypt.

## Docs Directory

| File | Purpose |
|------|---------|
| `SESSION-STATE.md` | Current session context (read on resume) |
| `TODO.md` | Active tasks and backlog |
| `TMUX-ISSUES.md` | Tmux performance investigation |
| `FUTURE-IDEAS.md` | Enhancement ideas |
| `AUDIT-2026-04-07.md` | Configuration audit with 23 findings |
| `PLAN-*.md` | Task-specific plans (created as needed) |
