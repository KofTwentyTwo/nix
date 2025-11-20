# Nix-Darwin & Home Manager Configuration

Personal Nix configuration for macOS using nix-darwin and Home Manager.

> **Note:** Currently macOS-only. Linux support is planned (see [TODO.md](./TODO.md)).

## Features

- **macOS System Configuration**: Dock, Finder, keyboard, security settings
- **Home Manager**: User environment, packages, and application configs
- **1Password Integration**: SSH agent and secure environment variable loading
- **Portable**: Easy to deploy across multiple Mac machines
- **Well Documented**: Comprehensive comments and documentation

## Quick Start

### Automated Setup (Recommended)

Run this one-liner on a fresh macOS machine:

```bash
curl -fsSL https://raw.githubusercontent.com/KofTwentyTwo/nix/main/bootstrap.sh | bash
```

This script will:
- ✅ Check for macOS
- ✅ Install Nix (if not present)
- ✅ Clone the repository
- ✅ Configure user settings interactively
- ✅ Build and activate the configuration
- ✅ Install WezTerm terminfo (if needed)

### Manual Setup

If you prefer manual setup:

1. **Install Nix** (if not already installed):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone this repository**:
   ```bash
   mkdir -p ~/.config
   cd ~/.config
   git clone git@github.com:KofTwentyTwo/nix.git
   cd nix
   ```

3. **Customize for your machine**:
   - Edit `flake.nix` and update the `userConfig` definition (around line 42)
   - Update username, git info, and paths as needed

4. **Build and activate**:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

5. **Install WezTerm terminfo** (if using WezTerm):
   ```bash
   tempfile=$(mktemp) \
     && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
     && tic -x -o ~/.terminfo $tempfile \
     && rm $tempfile
   ```

## Configuration Structure

```
.
├── flake.nix              # Main flake definition and macOS system config
├── user-config.nix        # Documentation template (actual config in flake.nix)
├── PORTABILITY.md         # Guide for deploying to different machines
├── SECRETS.md            # Documentation for 1Password secret management
├── README.md             # This file
└── home/                 # Home Manager modules
    ├── default.nix       # Main Home Manager config
    ├── 1password/        # 1Password integration
    ├── ca-certs/         # CA certificates
    ├── k9s/              # Kubernetes terminal UI
    ├── ohmyzsh/          # Oh My Zsh configuration
    ├── ssh/              # SSH client configuration
    ├── starship/         # Starship prompt
    ├── wez/              # WezTerm terminal
    └── zsh/              # Zsh shell configuration
```

## Key Features

### 1Password Integration

- **SSH Agent**: Automatic 1Password SSH agent integration
- **Secret Loading**: `op-load-secrets` function loads environment variables from 1Password
- See [SECRETS.md](./SECRETS.md) for detailed documentation

### Portability

- **User Configuration**: Centralized in `flake.nix` (userConfig definition)
- **Portable Paths**: Uses home directory variables instead of hardcoded paths
- See [PORTABILITY.md](./PORTABILITY.md) for deployment guide

### Package Management

- **Homebrew**: Managed via nix-darwin (brews, casks, masApps)
- **Nix Packages**: Managed via Home Manager
- **Fonts**: System-wide font installation

## Common Commands

```bash
# Rebuild configuration
darwin-rebuild switch --flake ~/.config/nix

# Check configuration (dry-run)
darwin-rebuild check --flake ~/.config/nix

# Update flake inputs
nix flake update

# View available options
man configuration.nix  # For nix-darwin options
```

## Documentation

- **[PORTABILITY.md](./PORTABILITY.md)**: Guide for deploying to different machines
- **[SECRETS.md](./SECRETS.md)**: 1Password secret management documentation
- **[user-config.nix](./user-config.nix)**: Template for user-specific configuration

## Machine-Specific Configuration

To customize for a different machine, edit `flake.nix` and update the `userConfig` definition:

```nix
userConfig = {
  username = "your.username";
  git = {
    userName = "Your Name";
    userEmail = "your@email.com";
    signingKey = "YOUR_GPG_KEY_ID";
  };
  paths = {
    qqqDevTools = "/path/to/dev/tools";  # Optional
    aicommitsPrompt = "/path/to/prompt.txt";  # Optional
  };
};
```

## Troubleshooting

### Build Errors

- **Pure evaluation errors**: Make sure `userConfig` is defined inline in `flake.nix`, not imported
- **File conflicts**: Home Manager will automatically back up existing files (`.backup` extension)

### 1Password Issues

- Ensure 1Password CLI is installed: `brew install 1password-cli`
- Sign in: `op signin`
- Check vault exists: `op vault list`

### SSH Issues

- Verify 1Password SSH agent is running
- Check SSH config: `~/.ssh/config`

## References

- [Nix Academy - Nix on macOS](https://nixcademy.com/posts/nix-on-macos/)
- [Nix-Darwin Guide](https://davi.sh/blog/2024/01/nix-darwin/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix-Darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)

## Linux Support

Linux support is planned but not yet implemented. See:
- [TODO.md](./TODO.md) - Planned improvements including Linux support
- [LINUX.md](./LINUX.md) - Detailed Linux migration guide
- [LINUX_SETUP.md](./LINUX_SETUP.md) - Quick Linux setup guide

The Home Manager modules are mostly portable and will work on Linux with a Linux-compatible flake wrapper.

## TODO / Future Improvements

See [TODO.md](./TODO.md) for planned improvements, including:
- Linux support
- Additional tools and utilities
- Configuration enhancements
- Documentation improvements

## License

See [LICENSE](./LICENSE) file.
