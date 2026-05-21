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

The following custom scripts are installed to `~/.local/bin/` by this Nix configuration:

### System & Update Management
* **`check-updates.sh`**: Checks Homebrew and Nix flake inputs for available updates. Runs daily at 9:00 AM via launchd or can be run manually.
* **`update-nix.sh`**: Updates all Nix flake inputs and rebuilds/switches the system configuration.

### Git & Workspace Orchestration
* **`git-pane-info.sh`**: Asynchronously queries and outputs Git repository name and branch for the tmux border status. Prevents input lag on large or slow repositories by caching status and running background updates.
* **`git-info.sh`**: Displays comprehensive status, branch, and remote configuration for a repository, including clickable URLs.
* **`git-sync-all.sh`**: Morning synchronization script. Fetches, switches to the default branch, and pulls updates across all repositories in the active directory.
* **`git-status-all.sh`**: Displays a clean status summary for all Git repositories in the current directory.
* **`git-fetch-all.sh`**: Fetches updates from remotes for all repositories in the current directory.
* **`git-pull-all.sh`**: Pulls updates for all clean repositories in the current directory (skips repositories with uncommitted changes).
* **`git-branch-all.sh`**: Shows current branch and status for all repositories in the current directory with a summary count.
* **`git-checkout-all.sh`**: Checks out a specified branch in all repositories in the current directory.
* **`git-log-all.sh`**: Displays recent commits across all repositories in the current directory.
* **`git-clone-all.sh`**: Clones all repositories from a specified GitHub organization.
* **`git-help.sh`**: Displays reference guide of all custom Git scripts and Oh-My-Zsh Git aliases.
* **`fix-git-remote.sh`**: Resolves common Git remote URL mismatches and protocol switches.
* **`gitops-publish.sh`**: Publishes a feature branch tag for GitOps deployment pipelines.

### Tmux & Utilities
* **`tmux-help.sh`**: Displays a searchable list of tmux keybindings and commands.
* **`tmux-lock.sh`**: Displays screensavers and locks the active tmux session.
* **`tmux-lock-set-pin.sh`**: Configures the tmux lock screen PIN.
* **`tmux-pin-check.sh`**: Helper script to validate the entered PIN against the hash.
* **`tmux-session-name.sh`**: Prompts the user to name a new tmux session on creation.
* **`tmux-session-rename.sh`**: Helper to rename a tmux session and update the client state.
* **`claude-resume.sh`**: Resumes a Claude Code session for the current directory.
* **`confluence.sh`**: Full-featured Confluence integration tool for reading, updating, and formatting Confluence pages and blog posts.
* **`confluence-blog.sh`**: Formats and publishes a blog post to Confluence.


