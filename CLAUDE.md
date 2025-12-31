# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

This is a **nix-darwin + Home Manager** configuration for macOS (Apple Silicon). The configuration manages both system-level macOS settings and user environment via a single Nix flake.

### Core Structure

- **flake.nix**: Entry point containing:
  - `userConfig`: User-specific settings (username, git config, paths)
  - `configuration`: nix-darwin system settings (macOS defaults, Homebrew, dock, firewall)
  - `homeconfig`: Home Manager user environment (packages, git, imports `./home`)
  - Machine definitions: `Darth`, `Grogu`, `Renova`
  - PAM config: Touch ID for sudo with `pam-reattach` for tmux support

- **home/default.nix**: Main Home Manager module that imports all sub-modules

### Home Manager Modules (`home/*/default.nix`)

Each module is self-contained and manages one concern:
- `1password/`: SSH agent integration and `op-load-secrets` function
- `ai/`: AI assistant configuration files (generates `~/.ai/*`)
- `aws/`: AWS config and credentials
- `ca-certs/`: CA certificate management
- `claude/`: Claude Code settings, permissions, and MCP server configuration
- `gpg/`: GPG key management
- `k9s/`: Kubernetes TUI config
- `nvim/`: Neovim setup
- `ohmyzsh/`: Oh My Zsh with plugins
- `scripts/`: Custom shell scripts
- `ssh/`: SSH client config
- `starship/`: Starship prompt theme (green borders, nerd fonts)
- `tmux/`: Tmux with screensaver and hacker status bar
- `updates/`: LaunchAgent for update checking
- `wez/`: WezTerm terminal (auto-starts tmux)
- `zsh/`: Zsh configuration and aliases

### Key Patterns

**Adding packages**: Homebrew packages go in `flake.nix` under `homebrew.brews` or `homebrew.casks`. Nix packages go in `home/default.nix` under `home.packages`.

**Creating new modules**: Add directory under `home/` with `default.nix`, then import in `home/default.nix`.

**File generation**: Use `home.file."path".text` or `home.file."path".source`.

**After tmux config changes**: Must run `tmux kill-server` for changes to take effect.

### Secrets

Encrypted files use git-crypt. After cloning, run `git-crypt unlock`.

## Current Configuration Details

### Tmux Setup (`home/tmux/default.nix`)
- **Screensaver**: cmatrix triggers after 15 minutes idle
- **Status bar**: Two-line hacker aesthetic matching starship prompt
  - Top line: Green separator
  - Bottom: Session name, window, user@host, load avg, clock, date
- **Colors**: Green/yellow/purple/cyan on black, nerd font icons
- **WezTerm integration**: Auto-starts tmux on new terminals
- **Touch ID**: Works in tmux via pam-reattach

### Constraints (do not violate)
- No mouse option changes in tmux
- No clipboard option changes in tmux
- No keybinding changes in tmux
- Keep tmux config minimal beyond screensaver and status bar
