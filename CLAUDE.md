# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build and activate configuration
darwin-rebuild switch --flake ~/.config/nix

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
  - `userConfig`: User-specific settings (username, git config, paths) - edit this for different machines
  - `configuration`: nix-darwin system settings (macOS defaults, Homebrew packages, dock, firewall)
  - `homeconfig`: Home Manager user environment (packages, git, imports `./home`)
  - Machine definitions: `Darth`, `Grogu`, `Renova` - named darwin configurations

- **home/default.nix**: Main Home Manager module that:
  - Imports all sub-modules from `./home/*`
  - Defines `sessionPath` and `sessionVariables`
  - Installs common packages and fonts

### Home Manager Modules (`home/*/default.nix`)

Each module is self-contained and manages one concern:
- `1password/`: SSH agent integration and `op-load-secrets` function
- `ai/`: AI assistant configuration files (generates `~/.ai/*`)
- `aws/`: AWS config and credentials
- `zsh/`: Zsh configuration and aliases
- `ohmyzsh/`: Oh My Zsh with plugins
- `starship/`: Starship prompt theme
- `wez/`: WezTerm terminal configuration
- `ssh/`: SSH client config
- `nvim/`: Neovim setup
- `k9s/`: Kubernetes TUI config
- `scripts/`: Custom shell scripts
- `updates/`: LaunchAgent for update checking
- `ca-certs/`: CA certificate management

### Key Patterns

**Adding packages**: Homebrew packages go in `flake.nix` under `homebrew.brews` or `homebrew.casks`. Nix packages go in `home/default.nix` under `home.packages` or in `flake.nix` under `homeconfig.home.packages`.

**Creating new modules**: Add a new directory under `home/` with a `default.nix`, then import it in `home/default.nix`.

**User configuration**: Machine-specific values come from `userConfig` in `flake.nix`, passed to Home Manager modules via `extraSpecialArgs`.

**File generation**: Use `home.file."path".text` or `home.file."path".source` to generate dotfiles.

### Secrets

Encrypted files use git-crypt. After cloning, run `git-crypt unlock`. Git hooks auto-unlock after pull.
