#!/usr/bin/env bash
# Bootstrap script for Nix-Darwin & Home Manager configuration
# Usage: curl -fsSL https://raw.githubusercontent.com/KofTwentyTwo/nix/main/bootstrap.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="git@github.com:KofTwentyTwo/nix.git"
REPO_DIR="$HOME/.config/nix"
NIX_CONFIG_DIR="$HOME/.config/nix"

# Helper functions
info() {
  echo -e "${CYAN}ℹ${NC} $1"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

error() {
  echo -e "${RED}✗${NC} $1" >&2
}

step() {
  echo -e "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if running on macOS
check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is designed for macOS only"
    exit 1
  fi
  success "Running on macOS"
}

# Install Nix if not present
install_nix() {
  if command_exists nix; then
    success "Nix is already installed: $(nix --version)"
    return 0
  fi

  step "Installing Nix..."
  info "This will install Nix using the Determinate Systems installer"
  
  if [[ -t 0 ]]; then
    # Interactive mode
    read -p "Continue with Nix installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      error "Nix installation cancelled"
      exit 1
    fi
  fi

  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  
  # Source nix in current shell
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  
  success "Nix installed successfully"
}

# Clone repository
clone_repo() {
  if [[ -d "$REPO_DIR" ]]; then
    warning "Repository directory already exists: $REPO_DIR"
    if [[ -t 0 ]]; then
      read -p "Remove and re-clone? (y/N) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
      else
        info "Using existing repository"
        return 0
      fi
    else
      info "Using existing repository"
      return 0
    fi
  fi

  step "Cloning repository..."
  
  # Check if SSH key is available
  if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    warning "SSH authentication to GitHub may not be set up"
    info "You may need to use HTTPS or set up SSH keys"
    read -p "Use HTTPS instead? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      REPO_URL="https://github.com/KofTwentyTwo/nix.git"
    fi
  fi

  mkdir -p "$HOME/.config"
  git clone "$REPO_URL" "$REPO_DIR"
  success "Repository cloned to $REPO_DIR"
}

# Configure user settings
configure_user() {
  step "Configuring user settings..."
  
  local current_user=$(whoami)
  info "Detected username: $current_user"
  
  if [[ -t 0 ]]; then
    read -p "Enter your username (default: $current_user): " username
    username=${username:-$current_user}
    
    read -p "Enter your Git name (default: $(git config --global user.name 2>/dev/null || echo '')): " git_name
    read -p "Enter your Git email (default: $(git config --global user.email 2>/dev/null || echo '')): " git_email
    read -p "Enter your GPG signing key (optional): " gpg_key
  else
    # Non-interactive mode - use defaults
    username="$current_user"
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")
    gpg_key=""
  fi

  # Update flake.nix with user config
  cd "$REPO_DIR"
  
  # Create a backup
  cp flake.nix flake.nix.bootstrap-backup
  
  # Update userConfig in flake.nix
  # This is a simple sed replacement - you may want to make this more robust
  if [[ -n "$git_name" ]] && [[ -n "$git_email" ]]; then
    # Find and replace username
    sed -i.bak "s/username = \"james.maes\"/username = \"$username\"/" flake.nix
    
    # Find and replace git userName
    if [[ -n "$git_name" ]]; then
      sed -i.bak "s/userName = \"James Maes\"/userName = \"$git_name\"/" flake.nix
    fi
    
    # Find and replace git userEmail
    if [[ -n "$git_email" ]]; then
      sed -i.bak "s/userEmail = \"james@kof22.com\"/userEmail = \"$git_email\"/" flake.nix
    fi
    
    # Update GPG key if provided
    if [[ -n "$gpg_key" ]]; then
      sed -i.bak "s/signingKey = \"62859E8ABE1FC2B7FCCB89080021767055740E6D\"/signingKey = \"$gpg_key\"/" flake.nix
    fi
    
    rm -f flake.nix.bak
    success "User configuration updated in flake.nix"
    info "You can manually edit flake.nix to customize paths and other settings"
  else
    warning "Git name/email not provided - using defaults"
    info "Please edit flake.nix manually to configure git settings"
  fi
}

# Build configuration
build_config() {
  step "Building Nix configuration..."
  
  cd "$REPO_DIR"
  
  # Check if we're on the right hostname
  local hostname=$(hostname -s)
  info "Detected hostname: $hostname"
  
  if [[ -t 0 ]]; then
    read -p "Use configuration for '$hostname'? (Y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      read -p "Enter hostname (Darth/Grogu): " hostname
    fi
  fi
  
  # Capitalize first letter
  hostname=$(echo "$hostname" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
  
  info "Building configuration for: $hostname"
  
  # Build and switch
  if sudo darwin-rebuild switch --flake "$REPO_DIR#$hostname"; then
    success "Configuration built and activated successfully!"
  else
    error "Build failed. Check the error messages above."
    exit 1
  fi
}

# Install WezTerm terminfo (if using WezTerm)
install_wezterm_terminfo() {
  if command_exists wezterm; then
    step "Installing WezTerm terminfo..."
    tempfile=$(mktemp)
    if curl -o "$tempfile" https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo 2>/dev/null; then
      tic -x -o ~/.terminfo "$tempfile"
      rm "$tempfile"
      success "WezTerm terminfo installed"
    else
      warning "Failed to download WezTerm terminfo (optional)"
    fi
  fi
}

# Main execution
main() {
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║                                                          ║"
  echo "║     🚀 Nix-Darwin & Home Manager Bootstrap 🚀           ║"
  echo "║                                                          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}\n"
  
  check_macos
  install_nix
  clone_repo
  configure_user
  build_config
  install_wezterm_terminfo
  
  echo -e "\n${GREEN}${BOLD}✅ Setup Complete!${NC}\n"
  echo -e "Your Nix configuration is now active."
  echo -e "To update in the future, run:"
  echo -e "  ${CYAN}cd ~/.config/nix && darwin-rebuild switch --flake ~/.config/nix${NC}\n"
  
  if [[ -t 0 ]]; then
    echo -e "Opening a new shell is recommended to load all changes."
  fi
}

# Run main function
main "$@"

