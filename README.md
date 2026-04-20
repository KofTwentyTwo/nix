# Ultimate AI Developer Terminal

Declarative macOS developer environment powered by **nix-darwin + Home Manager**. One flake manages system configuration, 160+ packages, terminal aesthetics, AI agent tooling, and custom scripts across multiple Apple Silicon machines.

> Single command to deploy: `darwin-rebuild switch --flake ~/.config/nix`

## What This Is

A fully reproducible development environment that turns a stock Mac into an opinionated, keyboard-driven workstation with deep AI integration. Everything from Dock layout to tmux lock-screen PINs is defined in Nix and version-controlled.

**Machines managed:** Darth, Grogu, Renova, Dark-Horse (all Apple Silicon)

---

## Quick Start

### Automated Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/KofTwentyTwo/nix/main/bootstrap.sh -o /tmp/bootstrap.sh && bash /tmp/bootstrap.sh
```

The bootstrap script handles: Nix installation, Homebrew, repo clone, git-crypt unlock, age key generation, machine registration in `flake.nix`, and initial build.

### Manual Setup

```bash
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone and enter
mkdir -p ~/.config && cd ~/.config
git clone git@github.com:KofTwentyTwo/nix.git && cd nix

# 3. Unlock encrypted files
git-crypt unlock

# 4. Build and activate
sudo darwin-rebuild switch --flake ~/.config/nix
```

### Day-to-Day Commands

| Command | Description |
|---------|-------------|
| `switch` | Rebuild and activate (alias for full darwin-rebuild) |
| `nix flake update` | Update all flake inputs |
| `darwin-rebuild check --flake ~/.config/nix` | Dry-run / validate |
| `check-updates` | Check for brew and nix updates |

---

## Architecture

```
flake.nix                    Entry point: inputs, machines, system config
modules/
  homebrew.nix               All brew formulae (161), casks (60+), masApps (9)
home/
  default.nix                Hub: imports all modules, env vars, PATH, programs
  ai/                        AI agent rules, profile, coding style, preferences
  claude/                    Claude Code: MCP servers, 100+ skills, permissions
  nvim/                      Neovim + LazyVim (60+ plugins, 13 LSP servers)
  tmux/                      Tmux: lock screen, session naming, nested SSH
  wez/                       WezTerm: GPU terminal with rich status bar
  zsh/                       Zsh: aliases, wrappers, oh-my-zsh, 100+ tips
  starship/                  Multi-line prompt with git/k8s/host awareness
  scripts/                   23 custom scripts installed to ~/.local/bin/
  ssh/                       SSH hosts + 1Password agent
  aws/                       AWS profiles (credentials encrypted via sops)
  gpg/                       GPG signing + pinentry-mac
  sops/                      Age-encrypted secrets (auto-decrypt on build)
  1password/                 1Password agent config + secret loader
  k9s/                       Kubernetes TUI favorites
  python/                    Python packages + pipx apps
  procs/                     Modern ps replacement config
  updates/                   Daily update checker (launchd)
  ca-certs/                  Custom CA certificate bundle
  ohmyzsh/                   Oh-My-Zsh plugin list
  codex/                     OpenAI Codex agent config
  gemini/                    Google Gemini agent config
  opencode/                  OpenCode agent config
scripts/                     Script source files (installed by home/scripts/)
docs/                        Session state, TODOs, plans, audit reports
```

---

## Terminal Stack

### WezTerm (GPU-Accelerated Terminal)

The terminal emulator layer. OpenGL frontend at 60 FPS with a custom hacker-aesthetic status bar.

**Status Bar (bottom):**
- **Left:** user@host, process name, k8s context, working directory, git branch + starship-style status indicators
- **Right:** network RX/TX rates, load average (color-coded), battery, date, time

**Features:**
- Auto-starts tmux on every new window/split (`default_prog = tmux new-session`)
- SSH host detection from process tree (status bar turns orange when remote)
- Git status caching (2s interval) with full starship-style indicators: `=`conflicts, `⇡`ahead, `⇣`behind, `⇕`diverged, ``stashed, `++`staged, ``modified, ``untracked
- Splits spawn new tmux sessions inheriting the current pane's working directory
- Screen management: `Cmd+`` cycles screens, `Cmd+0` moves to largest
- Pane navigation: `Cmd+h/j/k/l` or `Cmd+arrows`

### Tmux (Terminal Multiplexer)

Session management layer with a custom lock screen and hacker-style status bar.

**Status Bar (2 rows):**
```
Row 0: ────────────────────────────────────────────── (green separator)
Row 1:   SessionName ░▒▓ 1:zsh          hostname |  14:30 | 󰃰 20-Apr-26
```

**Pane Border (top of each pane):**
```
[repo-name] [branch] ──────────────────── [~/path/to/dir]────
```

**Session Naming:** Every new session prompts "Name this session (Enter to skip):" via a `session-created` hook. Sessions created with explicit names (e.g., `tmux new -s work`) skip the prompt.

**Lock Screen:** After 15 minutes idle, cmatrix screensaver + rolling PIN unlock. Manual trigger: `prefix+L`. PIN set on first session via popup.

**Nested SSH:** Press `F12` to toggle local keys off, letting the prefix reach remote tmux. Status bar dims to gray with a `REMOTE` indicator. Press `F12` again to restore.

**Command Palette:** `prefix+Space` opens a searchable fzf popup with all keybindings and commands.

**Other:** Mouse scroll enters copy mode, PageUp/PageDown for history, 50k history limit, OSC 52 clipboard, true color (24-bit), tmux-thumbs for link targeting.

### Zsh (Shell)

The interactive shell layer with extensive customization.

**Custom Functions:**
- **`ls()` wrapper** -- Translates classic ls flags to eza. `-t` becomes `--sort=modified`, `-S` becomes `--sort=size`, etc. The real ls flags work transparently.
- **`shelp`** -- 400+ line searchable reference for all tools, aliases, keybindings, and scripts. Supports `shelp` (full list) or `shelp kubectl` (filtered).
- **`hint()`** -- Random shell tip from a curated 100+ tip database, displayed in a dynamically-sized box on login.
- **`hg()`** -- History grep via ripgrep across full 100k history.
- **`fco()`** -- fzf-powered git branch picker.
- **`flog()`** -- fzf-powered commit browser with diff preview.

**Modern CLI Replacements (aliased globally):**

| Original | Replacement | Why |
|----------|-------------|-----|
| `cat` | `bat` | Syntax highlighting, line numbers |
| `ls` | `eza` (via wrapper) | Colors, git status, icons |
| `cd` | `zoxide` (`z`) | Learns frequent directories |
| `grep` | `ripgrep` (`rg`) | Faster, respects .gitignore |
| `find` | `fd` | Simpler syntax, faster |
| `du` | `dust` | Visual, sorted, colored |
| `df` | `duf` | Table layout with colors |
| `diff` | `difftastic` | Structural, syntax-aware |
| `ps` | `procs` | Tree view, search, color-coded |
| `dig` | `doggo` | Colored DNS, JSON output |
| `top` | `btop` | Graphs, resource monitor |
| `traceroute` | `mtr` | Live updating ping+trace |
| `man` | `bat -l man` | Syntax-highlighted man pages |
| `ncdu` | `ncdu --color dark-bg --show-graph --apparent-size --show-percent` | Better defaults |

**50+ Aliases:** `switch` (rebuild nix), `k` (kubectl), `h` (helm), git orchestration (`gsa`, `gsall`, `gfa`, `gpa`), `fast` (speed test), `secure` (load 1Password secrets), and more.

**Oh-My-Zsh Plugins:** git, sudo (double-ESC), docker, kubectl, aws, helm, terraform, fzf, aliases, extract (universal archive).

**Login Experience:**
1. `fastfetch` system info
2. Random shell tip in a bordered box
3. Update notification banner (if available)

### Starship (Prompt)

Multi-line prompt matching the hacker aesthetic:

```
┌───────────────────>
│ 󰀵 james on darth at ~/projects via  main [⇡1 +2 !3]
└─>
```

Modules: OS icon, username, hostname (yellow), directory, git branch + status, kubernetes context (purple), terraform workspace.

### Neovim (Editor)

LazyVim-based configuration with 60+ plugins.

**LSP Servers (13):** lua_ls, pyright, ts_ls, jsonls, yamlls, marksman, dockerls, gopls, rust_analyzer, clangd, bashls, nil_ls (Nix)

**Key Plugins:** tokyonight colorscheme, gitsigns (blame, hunks), nvim-cmp (completion), lsp_signature (inline hints), trouble.nvim (diagnostics), toggleterm (floating terminal), Comment.nvim, nvim-ts-autotag, schemastore (JSON/YAML schemas), claudecode.nvim (Claude Code integration)

**Claude in Neovim:** `<leader>ac` toggles Claude Code, `<leader>af` focuses it. Uses the claudecode.nvim plugin which reduces tmux flickering.

---

## AI Integration

### Claude Code (Primary)

Deep integration as the primary AI coding assistant.

**MCP Servers:**
| Server | Purpose |
|--------|---------|
| GitHub | GitHub API (issues, PRs, comments) |
| CircleCI | CI/CD (logs, flaky tests, pipeline status) |
| Atlassian | Jira/Confluence (issues, transitions, wiki) |
| QQQ-MCP | Custom local service (localhost:8080) |

**100+ Skills** from 10 repositories covering:
- Product management (PRDs, user stories, sprint planning, OKRs, discovery)
- Creative writing (drafting, critique, brainstorming, character simulation)
- Obsidian vault integration
- Code review, PR review, feature development
- Session continuity (start/end skills with state persistence)

**19 Official Plugins:** agent-sdk-dev, claude-md-management, code-review, commit-commands, feature-dev, frontend-design, playwright, pr-review-toolkit, context7, and more.

**Permissions:** 100+ granular allow rules for git, bash tools, file operations, Jira, GitHub, CircleCI, and development toolchains.

### Multi-Agent Configuration

AI rules and preferences are managed as Nix-generated files in `~/.ai/`:

| File | Purpose |
|------|---------|
| `1-profile.md` | Who I am, expertise, communication preferences |
| `2-coding-style.md` | Engineering conventions (Java, Nix, shell) |
| `3-rules.md` | Behavioral mandates (MUST/MUST NOT per RFC 2119) |
| `4-preferences.yaml` | Machine-readable tuning knobs |

These files are loaded by Claude Code and mirrored to other agents:
- **Gemini** (`~/.gemini/GEMINI.md`)
- **Codex** (`~/.codex/AGENTS.md`)
- **OpenCode** (`~/.config/opencode/opencode.json`)

---

## Package Management

### Homebrew (modules/homebrew.nix)

Managed declaratively through nix-darwin. Packages not in the list get uninstalled on rebuild.

**161 Formulae** including:
- **Languages:** Node.js (v20, v22), Go, Rust, Python 3.13, Julia, Java 21, GraalVM, LLVM
- **Kubernetes:** kubectl, k9s, kubectx, krew, helm, helmfile, kustomize, velero, kubeseal, argocd, stern, talosctl
- **Databases:** PostgreSQL 17, MySQL 8.4, Liquibase
- **DevOps:** Ansible, Terraform, OpenTofu, Terragrunt, Docker, SaltStack
- **Security:** gnupg, sops, cosign, nmap, age, gitleaks
- **Quality:** semgrep, ast-grep, shellcheck, yamllint, sqlfluff

**60+ Casks:** 1Password, Alfred, Docker Desktop, IntelliJ IDEA, JetBrains Toolbox, Obsidian, Ollama, Slack, VS Code, WezTerm, and more.

**9 Mac App Store Apps:** 1Password Safari, Airmail, GarageBand, iMovie, Keynote, Numbers, Pages, Parcel, Xcode.

### Nix Packages (home/default.nix)

Fonts (all Nerd Fonts, cozette, scientifica, monocraft) and utilities like `comma` (run any nix package without installing).

---

## Custom Scripts

23 scripts installed to `~/.local/bin/` via Home Manager:

**Git Orchestration (multi-repo):**
| Script | Alias | Purpose |
|--------|-------|---------|
| `git-sync-all.sh` | `gsa` | Fetch, switch branch, pull across all repos |
| `git-status-all.sh` | `gsall` | Status check for all repos |
| `git-clone-all.sh` | `gclo` | Clone all repos from a GitHub org |
| `git-fetch-all.sh` | `gfa` | Fetch updates for all repos |
| `git-pull-all.sh` | `gpa` | Pull all repos |
| `git-branch-all.sh` | `gba` | Show branches across repos |
| `git-checkout-all.sh` | `gcoa` | Checkout branch in all repos |
| `git-log-all.sh` | `gla` | Recent commits across repos |
| `git-info.sh` | `gi` | Comprehensive single-repo info |
| `git-help.sh` | `ghelp` | Show all custom git commands |
| `gitops-publish.sh` | `gt` | Publish feature branch tag for GitOps |

**Tmux Utilities:**
| Script | Purpose |
|--------|---------|
| `tmux-lock.sh` | Lock session with screensaver + PIN |
| `tmux-lock-set-pin.sh` | Configure lock PIN |
| `tmux-pin-check.sh` | Prompt for PIN on first session |
| `tmux-session-name.sh` | Interactive session naming on create |
| `tmux-help.sh` | Searchable command palette (fzf) |

**Other:** `check-updates.sh` (daily brew/nix check), `claude-resume.sh` (resume Claude session), `confluence-blog.sh` / `confluence.sh` (wiki integration).

---

## Security

| Layer | Implementation |
|-------|---------------|
| Secrets encryption | `sops-nix` with age keys (auto-decrypt on build) |
| Git encryption | `git-crypt` for AWS credentials |
| SSH agent | 1Password agent (no keys on disk) |
| GPG signing | All commits signed, 8-hour cache TTL |
| Secret loading | `op-load-secrets` pulls from 1Password vault |
| Sudo | Touch ID enabled (including inside tmux) |
| Firewall | Enabled with selective incoming rules |
| Updates | Daily automated check via launchd (9:00 AM) |
| Garbage collection | Weekly nix store cleanup (keep 7 days) |

---

## Adding a New Machine

1. Run `bootstrap.sh` on the new Mac (handles everything), or:
2. Add a new entry in `flake.nix` under `darwinConfigurations`:
   ```nix
   "new-hostname" = mkDarwinConfig {
     hostname = "new-hostname";
     isDeterminate = true;  # or false for standard nix-daemon
   };
   ```
3. Build: `sudo darwin-rebuild switch --flake ~/.config/nix#new-hostname`

## Adding Packages

- **Homebrew formula:** Add to `brews` list in `modules/homebrew.nix`
- **Homebrew cask:** Add to `casks` list in `modules/homebrew.nix`
- **Nix package:** Add to `home.packages` in `home/default.nix`
- **New module:** Create `home/foo/default.nix`, import in `home/default.nix`
- **Alias:** Add to `shellAliases` in `home/zsh/default.nix`
- **Env var:** Add to `sessionVariables` in `home/default.nix`
- **Script:** Add to `scripts/`, register in `home/scripts/default.nix`

---

## Documentation

| File | Purpose |
|------|---------|
| `docs/SESSION-STATE.md` | Current session context (for AI continuity) |
| `docs/TODO.md` | Active tasks and backlog |
| `docs/TMUX-ISSUES.md` | Tmux performance investigation |
| `docs/FUTURE-IDEAS.md` | Enhancement ideas |
| `docs/AUDIT-2026-04-07.md` | Configuration audit (23 findings) |
| `PORTABILITY.md` | Multi-machine deployment guide |
| `SECRETS.md` | 1Password secret management |
| `LINUX.md` / `LINUX_SETUP.md` | Planned Linux support |

## References

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Determinate Nix Installer](https://determinate.systems/nix-installer/)
- [WezTerm](https://wezfurlong.org/wezterm/)
- [LazyVim](https://www.lazyvim.org/)
- [Starship](https://starship.rs/)

## License

See [LICENSE](./LICENSE) file.
