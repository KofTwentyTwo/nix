# Scripts Module
# ==============
# Manages shared shell scripts that are available across all machines.
#
# Scripts are installed to ~/.local/bin/ which is already in PATH.
# All scripts are automatically made executable.
#
# Usage:
#   1. Add scripts to the scripts/ directory in the repo root
#   2. List them in the scripts array below
#   3. Rebuild: darwin-rebuild switch --flake ~/.config/nix
#
# Scripts will be available in your PATH immediately.
#
# Portability:
#   - Scripts are version controlled in the repo
#   - Available on all machines using this Nix config
#   - Automatically executable

{ config, pkgs, lib, ... }:

let
  # Path to scripts directory in the repo
  scriptsDir = ../../scripts;
in
{
  config = {
    # Install scripts to ~/.local/bin/ (already in PATH)
    # Each script is made executable automatically
    home.file = lib.listToAttrs (
      # List all scripts you want to install
      # Format: "script-name" = { source = ./scripts/script-name.sh; };
      map (scriptName: {
        name = ".local/bin/${scriptName}";
        value = {
          source = "${scriptsDir}/${scriptName}";
          executable = true;
        };
      }) [
        # Add your script filenames here
        # Scripts will be installed to ~/.local/bin/ and available in PATH
        "update-nix.sh"
        "gitops-publish.sh"
        "fix-git-remote.sh"
        "git-sync-all.sh"
        "git-status-all.sh"
        "git-clone-all.sh"
        "git-fetch-all.sh"
        "git-pull-all.sh"
        "git-branch-all.sh"
        "git-checkout-all.sh"
        "git-log-all.sh"
        "git-info.sh"
        "git-help.sh"
        "claude-resume.sh"
        "confluence-blog.sh"
        "confluence.sh"
        "tmux-help.sh"
        "tmux-lock.sh"
        "tmux-lock-set-pin.sh"
        "tmux-pin-check.sh"
        "tmux-session-name.sh"
        # Add more scripts as you create them:
        # "backup-config.sh"
        # "health-check.sh"
        # "my-custom-script.sh"
      ]
    );
  };
}

