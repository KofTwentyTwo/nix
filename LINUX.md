# Linux Support Guide
# ==================

Your current configuration is macOS-specific, but the Home Manager parts can work on Linux.

## Current Setup (macOS)

- Uses `nix-darwin` for system configuration
- Uses `darwin-rebuild switch` command
- Contains macOS-specific settings (dock, finder, etc.)
- Uses Homebrew for some packages

## Linux Options

### Option 1: Home Manager Standalone (Recommended for non-NixOS Linux)

Use only Home Manager on a regular Linux distribution (Ubuntu, Debian, Fedora, etc.):

1. **Install Nix** (if not already installed):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone the repository**:
   ```bash
   mkdir -p ~/.config
   cd ~/.config
   git clone git@github.com:KofTwentyTwo/nix.git
   cd nix
   ```

3. **Create a Linux-specific flake** (`flake-linux.nix`):
   ```nix
   {
     description = "Home Manager configuration for Linux";
     
     inputs = {
       nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
       home-manager = {
         url = "github:nix-community/home-manager";
         inputs.nixpkgs.follows = "nixpkgs";
       };
     };
     
     outputs = { self, nixpkgs, home-manager, ... }:
     let
       userConfig = {
         username = "your-username";  # Update this
         git = {
           userName = "Your Name";
           userEmail = "your@email.com";
           signingKey = "YOUR_GPG_KEY";
         };
         paths = {
           # Update paths for Linux (use /home/username instead of /Users/username)
         };
       };
       username = userConfig.username;
       system = "x86_64-linux";  # or "aarch64-linux" for ARM
     in
     {
       homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
         pkgs = import nixpkgs { inherit system; };
         modules = [
           ./home
         ];
         extraSpecialArgs = { userConfig = userConfig; };
       };
     };
   }
   ```

4. **Update paths in `home/default.nix`**:
   - Change `/Users/` to `/home/`
   - Update `userHome` to use Linux home directory

5. **Build and activate**:
   ```bash
   home-manager switch --flake ~/.config/nix#your-username
   ```

### Option 2: NixOS (Full Linux OS Configuration)

If you're using NixOS (Linux distribution built on Nix):

1. Create `configuration.nix` that imports your Home Manager config
2. Use `nixos-rebuild switch` instead of `darwin-rebuild switch`
3. Remove all macOS-specific settings

## What Needs to Change

### 1. Path Updates

In `home/default.nix` and `home/zsh/default.nix`:
- `/Users/username` → `/home/username`
- `/opt/homebrew/` → Remove (Homebrew is macOS-only)
- Update any macOS-specific paths

### 2. Remove macOS-Specific Modules

Remove or conditionally include:
- Homebrew configuration
- macOS system defaults
- Dock settings
- Finder settings

### 3. Package Manager

On Linux, you'd typically use:
- **Nix packages** (via Home Manager) - ✅ Already using
- **System package manager** (apt, dnf, etc.) - For system packages
- **No Homebrew** - Remove Homebrew references

### 4. Commands

- `darwin-rebuild switch` → `home-manager switch` (standalone) or `nixos-rebuild switch` (NixOS)

## Quick Migration Steps

1. **Create a Linux branch**:
   ```bash
   git checkout -b linux-support
   ```

2. **Create `flake-linux.nix`** (see Option 1 above)

3. **Update paths** in Home Manager modules:
   ```bash
   # Find and replace
   find home/ -type f -name "*.nix" -exec sed -i 's|/Users/|/home/|g' {} \;
   ```

4. **Remove macOS-specific configs** from `flake.nix` or create conditional includes

5. **Test on Linux machine**

## Recommended Approach

For maximum portability, consider:

1. **Keep macOS config as-is** (current `flake.nix`)
2. **Create separate Linux flake** (`flake-linux.nix`)
3. **Share Home Manager modules** (they work on both)
4. **Use conditional includes** for OS-specific settings

Example structure:
```
.
├── flake.nix              # macOS (nix-darwin)
├── flake-linux.nix        # Linux (Home Manager standalone)
├── flake-nixos.nix        # NixOS (optional)
└── home/                  # Shared Home Manager modules
    ├── default.nix
    ├── zsh/
    ├── nvim/
    └── ...
```

## Testing on Linux

1. Set up a Linux VM or machine
2. Install Nix
3. Clone your repo
4. Use the Linux flake
5. Adjust paths and remove macOS-specific configs

## Questions?

- **Home Manager standalone**: Best for Ubuntu/Debian/Fedora/etc.
- **NixOS**: Best if you want to manage the entire Linux system with Nix
- **Current setup**: Perfect for macOS, needs adaptation for Linux

