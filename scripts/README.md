# Shared Scripts
# ==============

This directory contains shell scripts that are shared across all your machines.

## How It Works

1. **Add scripts here** - Place your `.sh` scripts in this directory
2. **List in module** - Add script names to `home/scripts/default.nix`
3. **Rebuild** - Run `darwin-rebuild switch --flake ~/.config/nix`
4. **Use anywhere** - Scripts are available in your PATH as `~/.local/bin/script-name`

## Adding a New Script

### Step 1: Create the Script

```bash
# Create your script
cat > scripts/my-awesome-script.sh << 'EOF'
#!/usr/bin/env bash
# My awesome script
echo "Hello from my script!"
EOF

# Make it executable
chmod +x scripts/my-awesome-script.sh
```

### Step 2: Add to Module

Edit `home/scripts/default.nix` and add your script name to the list:

```nix
map (scriptName: {
  name = ".local/bin/${scriptName}";
  value = {
    source = "${scriptsDir}/${scriptName}";
    executable = true;
  };
}) [
  "my-awesome-script.sh"  # Add your script here
]
```

### Step 3: Rebuild

```bash
darwin-rebuild switch --flake ~/.config/nix
```

### Step 4: Use It

```bash
my-awesome-script.sh  # Available in PATH!
```

## Script Naming

- Scripts can have `.sh` extension or not - your choice
- If you want to call it without extension, name it without `.sh` in the list
- Example: Script file `update.sh` → List as `"update.sh"` → Call as `update.sh`
- Or: Script file `update.sh` → List as `"update"` → Call as `update`

## Best Practices

1. **Shebang**: Always start scripts with `#!/usr/bin/env bash` or `#!/usr/bin/env zsh`
2. **Error handling**: Use `set -euo pipefail` for safety (unless sourced)
3. **Documentation**: Add comments explaining what the script does
4. **Portability**: Use `$HOME` instead of hardcoded paths
5. **Version control**: Commit scripts to git so they're available everywhere

## Example Scripts

Here are some ideas for useful scripts:

- `update-nix.sh` - Update flake and rebuild
- `backup-config.sh` - Backup current Nix config
- `health-check.sh` - Check system health
- `sync-dotfiles.sh` - Sync dotfiles across machines
- `setup-project.sh` - Initialize a new project

## Current Scripts

(Add your scripts here as you create them)

