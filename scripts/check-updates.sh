#!/usr/bin/env bash
# Check for available updates in brew and nix flake
# Sets a notification file if updates are available
# This script is designed to run via launchd (macOS cron equivalent)

set -euo pipefail

# Colors for output (though this runs in background, useful for manual runs)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Path to notification file (in user's home directory)
NOTIFICATION_FILE="$HOME/.config/nix/.updates-available"
NIX_CONFIG_DIR="$HOME/.config/nix"

# Track if any updates are found
UPDATES_FOUND=false
UPDATE_MESSAGES=()

# Function to check brew updates
check_brew_updates() {
    if ! command -v brew >/dev/null 2>&1; then
        return 0  # Brew not installed, skip
    fi
    
    # Update brew's package database (quietly)
    brew update >/dev/null 2>&1 || true
    
    # Check for outdated packages
    local outdated=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$outdated" -gt 0 ]]; then
        UPDATES_FOUND=true
        UPDATE_MESSAGES+=("brew: $outdated package(s) outdated")
    fi
    
    # Check for outdated casks
    local outdated_casks=$(brew outdated --cask 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$outdated_casks" -gt 0 ]]; then
        UPDATES_FOUND=true
        UPDATE_MESSAGES+=("brew cask: $outdated_casks cask(s) outdated")
    fi
}

# Function to check nix flake updates
check_nix_updates() {
    if ! command -v nix >/dev/null 2>&1; then
        return 0  # Nix not available, skip
    fi
    
    # Check if we're in a git repository (for flake updates)
    if [[ ! -d "$NIX_CONFIG_DIR/.git" ]]; then
        return 0  # Not a git repo, skip flake update check
    fi
    
    # Check for flake updates
    cd "$NIX_CONFIG_DIR" || return 0
    
    # Get the last time we checked (stored in a separate file)
    local last_check_file="$NIX_CONFIG_DIR/.last-update-check"
    local should_check=true
    
    if [[ -f "$last_check_file" ]]; then
        local last_check=$(cat "$last_check_file" 2>/dev/null || echo "0")
        local now=$(date +%s)
        local six_hours_ago=$((now - 21600))  # 6 hours ago
        
        # Only check if it's been more than 6 hours since last check
        if [[ "$last_check" -gt "$six_hours_ago" ]]; then
            should_check=false
        fi
    fi
    
    if [[ "$should_check" != "true" ]]; then
        return 0  # Too soon to check again
    fi
    
    if [[ ! -f "flake.lock" ]]; then
        return 0  # No lock file
    fi
    
    # Fetch latest from remote (quietly)
    git fetch origin main >/dev/null 2>&1 || true
    
    # Check if remote has changes to flake.lock (indicates upstream updates)
    if ! git diff --quiet HEAD origin/main -- flake.lock 2>/dev/null; then
        UPDATES_FOUND=true
        UPDATE_MESSAGES+=("nix: flake inputs have updates available")
    else
        # Check if lock file is old (suggest manual check)
        local lock_age=$(stat -f "%m" flake.lock 2>/dev/null || stat -c "%Y" flake.lock 2>/dev/null || echo "0")
        local now=$(date +%s)
        local days_old=$(((now - lock_age) / 86400))
        
        # If lock file is more than 7 days old, suggest checking
        if [[ "$days_old" -gt 7 ]]; then
            UPDATES_FOUND=true
            UPDATE_MESSAGES+=("nix: flake lock file is $days_old day(s) old - consider checking for updates")
        fi
    fi
    
    # Update last check time
    echo "$(date +%s)" > "$last_check_file" 2>/dev/null || true
}

# Main execution
main() {
    # Change to home directory to avoid any path issues
    cd "$HOME" || exit 1
    
    # Check for updates
    check_brew_updates
    check_nix_updates
    
    # Create or remove notification file
    if [[ "$UPDATES_FOUND" == "true" ]]; then
        # Create notification file with update messages
        {
            echo "# Update notifications - $(date '+%Y-%m-%d %H:%M:%S')"
            echo "# Run 'brew upgrade' to update brew packages"
            echo "# Run 'nix flake update ~/.config/nix && darwin-rebuild switch --flake ~/.config/nix' to update nix"
            echo ""
            for msg in "${UPDATE_MESSAGES[@]}"; do
                echo "- $msg"
            done
        } > "$NOTIFICATION_FILE"
        
        # Log to syslog for debugging (optional)
        logger -t check-updates "Updates available: ${UPDATE_MESSAGES[*]}"
    else
        # No updates, remove notification file if it exists
        rm -f "$NOTIFICATION_FILE"
        logger -t check-updates "No updates available"
    fi
}

# Run main function
main "$@"
