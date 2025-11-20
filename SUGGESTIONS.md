# Suggested Additions to Nix Configuration

Based on your current setup, here are useful additions you might consider:

## 🚀 High-Value Additions

### 1. **Better File Utilities**
You have `ack` and `ripgrep`, but consider adding:
- **`bat`** - Better `cat` with syntax highlighting
- **`eza`** (or `exa`) - Modern `ls` replacement with colors and git status
- **`zoxide`** - Smarter `cd` that learns your habits
- **`fd`** - Faster `find` alternative (you have it via Homebrew, but could add to Nix)

### 2. **Git Enhancements**
- **`delta`** - Better git diff viewer
- **`git-delta`** - Configure git to use delta automatically
- **`gh`** - GitHub CLI (you have via Homebrew, but could configure via Home Manager)
- **`gitui`** - Terminal UI for git

### 3. **Development Tools**
- **`direnv`** - Auto-load environment variables per directory
- **`just`** - Modern command runner (like `make` but simpler)
- **`mise`** (formerly `rtx`) - Universal version manager (replaces asdf/nvm/pyenv)
- **`nix-direnv`** - Faster direnv for Nix projects

### 4. **Terminal Enhancements**
- **`tmux`** - Terminal multiplexer (if you use it)
- **`zellij`** - Modern terminal workspace
- **`atuin`** - Better shell history with sync
- **`fzf`** - Fuzzy finder (you have via Homebrew, but could configure better)

### 5. **System Monitoring**
- **`btop`** - You have it, but could add more monitoring
- **`procs`** - Modern `ps` replacement
- **`dust`** - Better `du` visualization
- **`bandwhich`** - Network utilization by process

## 📦 Home Manager Program Modules

These can be configured via Home Manager for better integration:

### Already Configured:
- ✅ `programs.git`
- ✅ `programs.zsh`
- ✅ `programs.ssh`
- ✅ `programs.starship`
- ✅ `programs.k9s`
- ✅ `programs.wezterm`
- ✅ `programs.nix-index`

### Consider Adding:

```nix
# In home/default.nix or a new module

# Better file viewer
programs.bat = {
  enable = true;
  config = {
    theme = "TwoDark";
    pager = "less -FR";
  };
};

# Modern ls replacement
programs.eza = {
  enable = true;
  enableAliases = true;  # Adds ls, ll, la, tree aliases
};

# Smart cd
programs.zoxide = {
  enable = true;
  enableZshIntegration = true;
};

# Better git diff
programs.delta = {
  enable = true;
  options = {
    syntax-theme = "TwoDark";
    line-numbers = true;
    side-by-side = true;
  };
};

# Configure git to use delta
programs.git.delta.enable = true;

# Direnv for per-directory environments
programs.direnv = {
  enable = true;
  enableZshIntegration = true;
  nix-direnv.enable = true;  # Faster Nix integration
};

# GitHub CLI
programs.gh = {
  enable = true;
  settings = {
    git_protocol = "ssh";
    editor = "nvim";
  };
};

# Fuzzy finder
programs.fzf = {
  enable = true;
  enableZshIntegration = true;
  defaultCommand = "fd --type f";
  defaultOptions = [ "--height 40%" "--border" ];
};

# Better man pages
programs.man = {
  enable = true;
  generateCaches = true;
};

# Neovim configuration (if you use it)
programs.neovim = {
  enable = true;
  viAlias = true;
  vimAlias = true;
  # Add your neovim config here or import from file
};
```

## 🔧 Utility Scripts

### 1. **Update Script**
Create `scripts/update.sh`:
```bash
#!/usr/bin/env bash
# Update Nix flake and rebuild
nix flake update
darwin-rebuild switch --flake ~/.config/nix
```

### 2. **Backup Script**
Create `scripts/backup.sh`:
```bash
#!/usr/bin/env bash
# Backup current configuration
git add -A
git commit -m "Backup: $(date +%Y-%m-%d)"
git push
```

### 3. **Health Check Script**
Create `scripts/health-check.sh`:
```bash
#!/usr/bin/env bash
# Check system health
echo "Checking Nix configuration..."
darwin-rebuild check --flake ~/.config/nix
echo "Checking 1Password..."
op account list
echo "Checking SSH..."
ssh -T git@github.com
```

## 🎨 Additional Packages to Consider

### Development
- `jq` - JSON processor (you might have this)
- `yq` - YAML processor
- `tree` - Directory tree viewer
- `unzip` / `zip` - Archive utilities
- `httpie` - Better curl alternative
- `dog` - Better dig alternative

### System
- `age` - Encryption tool
- `sops` - Secrets management
- `chezmoi` - Dotfile manager (if you want to manage other dotfiles)
- `stow` - Symlink manager

### Fun/Productivity
- `cowsay` / `fortune` - Terminal fun
- `tldr` - You have it, great!
- `glow` - Markdown viewer (you have via Homebrew)

## 🔐 Security Enhancements

### 1. **GPG Configuration**
```nix
programs.gpg = {
  enable = true;
  settings = {
    default-key = userConfig.git.signingKey;
  };
};
```

### 2. **SSH Additional Features**
- Add more SSH config options
- Configure SSH key forwarding
- Add jump hosts configuration

## 📝 Configuration Management

### 1. **Neovim Module** (if you use Neovim)
Create `home/nvim/default.nix`:
```nix
{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # Import your neovim config
  };
}
```

### 2. **Docker Module** (if you use Docker)
```nix
programs.docker = {
  enable = true;
  # Configure docker-compose, etc.
};
```

## 🚦 Priority Recommendations

**Start with these (highest impact):**
1. `bat` - You'll use it constantly
2. `eza` - Better ls experience
3. `zoxide` - Saves time navigating
4. `delta` - Better git diffs
5. `direnv` - Great for project-specific env vars

**Then consider:**
6. `fzf` configuration via Home Manager
7. `gh` configuration via Home Manager
8. `atuin` for better history
9. Update/backup scripts
10. Neovim configuration (if you use it)

## 📚 Resources

- [Home Manager Options](https://nix-community.github.io/home-manager/options.html)
- [NixOS Search](https://search.nixos.org/packages) - Find packages
- [Awesome Nix](https://github.com/nix-community/awesome-nix) - Curated list

## 💡 Quick Wins

These are easy to add and provide immediate value:

1. **Add to `home/default.nix` packages:**
   ```nix
   bat
   eza
   zoxide
   delta
   ```

2. **Add to `home/default.nix` programs:**
   ```nix
   programs.bat.enable = true;
   programs.eza.enable = true;
   programs.zoxide.enable = true;
   programs.delta.enable = true;
   ```

3. **Add aliases to `home/zsh/default.nix`:**
   ```nix
   shellAliases = {
     # ... existing aliases ...
     cat = "bat";
     ls = "eza";
     ll = "eza -l";
     la = "eza -la";
     cd = "z";  # zoxide
   };
   ```

