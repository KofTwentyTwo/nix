# Portability Guide
# =================

This guide explains how to make this Nix configuration portable across different Mac machines.

## Quick Start

1. **Edit `flake.nix`** and update the `userConfig` definition (around line 40) with your username and paths
2. **Rebuild**: `darwin-rebuild switch --flake ~/.config/nix`

## User Configuration

**Note:** The actual user configuration is defined inline in `flake.nix` (not in `user-config.nix`). The `user-config.nix` file is just a template/reference.

The `userConfig` attribute set in `flake.nix` contains all user-specific settings:

- **username**: Your macOS username (e.g., "james.maes")
- **git**: Git user name, email, and signing key
- **paths**: Optional machine-specific paths

### Example

```nix
{
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
}
```

## What's Portable

✅ **Automatically portable** (uses home directory or variables):
- All Home Manager modules
- SSH configuration (default user from `userConfig` in `flake.nix`)
- Environment variables and paths
- Package installations
- Application configurations

## What Needs Manual Configuration

⚠️ **Machine-specific** (may need adjustment):

1. **SSH Host Configurations** (`home/ssh/default.nix`)
   - Many hosts have hardcoded usernames (e.g., "james.maes", "local_admin")
   - These are server-specific and should remain as-is
   - Only the default "*" block uses the username variable

2. **Java/GraalVM Paths** (`home/zsh/default.nix`)
   - System-wide Java installations are hardcoded
   - Update if Java is installed in a different location

3. **Dock Applications** (`flake.nix`)
   - Applications list is machine-specific
   - Remove apps that don't exist on other machines

4. **Homebrew Packages** (`flake.nix`)
   - Some packages may not be available on all machines
   - Comment out packages that aren't needed

## Platform Differences

### Apple Silicon vs Intel

The configuration is set for Apple Silicon (`aarch64-darwin`). For Intel Macs:

```nix
# In flake.nix, change:
nixpkgs.hostPlatform = "x86_64-darwin";  # For Intel Macs
```

### Different macOS Versions

- Update `system.stateVersion` in `flake.nix` if needed
- Update `home.stateVersion` in `flake.nix` if needed

## Testing Portability

1. Clone the repo on a new machine
2. Edit `flake.nix` and update the `userConfig` definition
3. Run: `darwin-rebuild switch --flake ~/.config/nix`
4. Check for any errors and adjust as needed

## Troubleshooting

### Path Not Found Errors

If you see errors about missing paths:
- Check the `userConfig.paths` section in `flake.nix` for optional paths
- Comment out paths that don't exist on the machine
- Some paths are checked at runtime (won't cause build failures)

### SSH Configuration

SSH hosts with specific usernames are intentional - they're server-specific.
Only update if you need different usernames for those servers.

### Missing Applications

If applications in the dock list don't exist:
- Remove them from `system.defaults.dock.persistent-apps` in `flake.nix`
- Or install them via Homebrew/MAS

## Best Practices

1. **Update `userConfig` in `flake.nix`** for each machine (it's inline, so changes are tracked per machine)
2. **Document machine-specific changes** in comments within `flake.nix`
3. **Test on a new machine** before relying on it
4. **Use variables** instead of hardcoded paths where possible
5. **Reference `user-config.nix`** as a template if you need to see the structure

