# Quick Linux Setup Guide
# =======================

## TL;DR

**Your current setup is macOS-only**, but ~80% of it (Home Manager modules) will work on Linux with minor changes.

## What Works on Linux ✅

- ✅ All Home Manager modules (zsh, ssh, starship, neovim, etc.)
- ✅ Most packages and configurations
- ✅ Application configs (neovim, starship, wezterm, etc.)
- ✅ Environment variables and paths (with path updates)

## What Doesn't Work ❌

- ❌ `nix-darwin` (macOS-only)
- ❌ macOS system settings (dock, finder, etc.)
- ❌ Homebrew (macOS package manager)
- ❌ `darwin-rebuild` command
- ❌ macOS-specific paths (`/Users/` → `/home/`)

## Quick Setup for Linux

### Step 1: Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Step 2: Clone Repository

```bash
mkdir -p ~/.config
cd ~/.config
git clone git@github.com:KofTwentyTwo/nix.git
cd nix
```

### Step 3: Create Linux Flake

Copy `flake-linux.nix.example` to `flake-linux.nix` and update:

```bash
cp flake-linux.nix.example flake-linux.nix
# Edit flake-linux.nix with your username and paths
```

### Step 4: Update Paths

In `home/default.nix`, change:
- `/opt/homebrew/bin/` → Remove or comment out
- `/opt/homebrew/opt/llvm/bin` → Remove or use system LLVM

### Step 5: Build

```bash
home-manager switch --flake ~/.config/nix#your-username
```

## Differences Summary

| macOS | Linux |
|-------|-------|
| `darwin-rebuild switch` | `home-manager switch` |
| `/Users/username` | `/home/username` |
| Homebrew | System package manager or Nix |
| nix-darwin | Home Manager standalone or NixOS |
| `flake.nix` | `flake-linux.nix` |

## Recommended Approach

1. **Keep your macOS config** as-is (`flake.nix`)
2. **Create separate Linux flake** (`flake-linux.nix`)
3. **Share Home Manager modules** (they work on both!)
4. **Use conditional paths** if you want one flake for both

See `LINUX.md` for detailed migration guide.

