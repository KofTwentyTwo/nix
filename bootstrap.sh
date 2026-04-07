#!/usr/bin/env bash
# Bootstrap script for Nix-Darwin & Home Manager configuration
# Usage: curl -fsSL https://raw.githubusercontent.com/KofTwentyTwo/nix/main/bootstrap.sh | bash
#
# What this does:
#   1. Installs Nix (Determinate Systems installer)
#   2. Installs Homebrew (if missing)
#   3. Clones this config repo to ~/.config/nix
#   4. Unlocks git-crypt encrypted files
#   5. Generates a sops-nix age key for this machine
#   6. Adds this machine to flake.nix (if not already present)
#   7. Builds and activates the configuration

set -euo pipefail

# Configuration
REPO_URL="git@github.com:KofTwentyTwo/nix.git"
REPO_DIR="$HOME/.config/nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}>>>${NC} $1"; }
success() { echo -e "${GREEN}>>>${NC} $1"; }
warn()    { echo -e "${YELLOW}>>>${NC} $1"; }
fail()    { echo -e "${RED}>>>${NC} $1" >&2; }
step()    { echo -e "\n${BOLD}--- $1 ---${NC}\n"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------------------- #
# Pre-flight checks
# --------------------------------------------------------------------------- #

preflight() {
  if [[ "$(uname)" != "Darwin" ]]; then
    fail "This script is for macOS only."
    exit 1
  fi

  if [[ "$(uname -m)" != "arm64" ]]; then
    warn "This config is designed for Apple Silicon. Intel may need adjustments."
  fi

  # Xcode CLI tools are needed for git
  if ! xcode-select -p &>/dev/null; then
    step "Installing Xcode Command Line Tools"
    xcode-select --install
    info "Waiting for Xcode CLI tools to install..."
    until xcode-select -p &>/dev/null; do sleep 5; done
    success "Xcode CLI tools installed"
  fi
}

# --------------------------------------------------------------------------- #
# Install Nix
# --------------------------------------------------------------------------- #

install_nix() {
  if command_exists nix; then
    success "Nix already installed: $(nix --version)"
    return 0
  fi

  step "Installing Nix"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

  # Source nix in current shell
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  success "Nix installed"
}

# --------------------------------------------------------------------------- #
# Install Homebrew
# --------------------------------------------------------------------------- #

install_homebrew() {
  if command_exists brew; then
    success "Homebrew already installed"
    return 0
  fi

  step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to current shell
  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed"
}

# --------------------------------------------------------------------------- #
# Clone repo
# --------------------------------------------------------------------------- #

clone_repo() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    success "Config repo already at $REPO_DIR"
    return 0
  fi

  step "Cloning config repo"

  # Test SSH, fall back to HTTPS
  if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    warn "SSH auth to GitHub not available. Using HTTPS."
    REPO_URL="https://github.com/KofTwentyTwo/nix.git"
  fi

  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
  success "Cloned to $REPO_DIR"
}

# --------------------------------------------------------------------------- #
# Unlock git-crypt
# --------------------------------------------------------------------------- #

unlock_gitcrypt() {
  step "Unlocking git-crypt"
  cd "$REPO_DIR"

  if ! command_exists git-crypt; then
    info "Installing git-crypt via Homebrew..."
    brew install git-crypt
  fi

  if git-crypt status &>/dev/null && git-crypt status | grep -q "encrypted:"; then
    if git-crypt unlock 2>/dev/null; then
      success "git-crypt unlocked with GPG key"
    else
      warn "Automatic unlock failed."
      read -rp "Path to git-crypt key file (or Enter to skip): " keyfile
      if [[ -n "$keyfile" ]] && [[ -f "$keyfile" ]]; then
        git-crypt unlock "$keyfile"
        success "git-crypt unlocked with key file"
      else
        warn "Skipped git-crypt unlock. Run 'git-crypt unlock' manually later."
      fi
    fi
  else
    success "git-crypt: nothing to unlock"
  fi
}

# --------------------------------------------------------------------------- #
# Set up sops-nix age key
# --------------------------------------------------------------------------- #

setup_age_key() {
  step "Setting up sops-nix age key"

  local age_dir="$HOME/.config/sops/age"
  local age_key="$age_dir/keys.txt"

  if [[ -f "$age_key" ]]; then
    success "Age key already exists at $age_key"
    local pubkey
    pubkey=$(grep "public key:" "$age_key" | awk '{print $NF}')
    info "Public key: $pubkey"
    return 0
  fi

  if ! command_exists age-keygen; then
    info "Installing age via Homebrew..."
    brew install age
  fi

  mkdir -p "$age_dir"
  age-keygen -o "$age_key" 2>&1
  chmod 600 "$age_key"

  local pubkey
  pubkey=$(grep "public key:" "$age_key" | awk '{print $NF}')
  success "Age key generated"
  info "Public key: $pubkey"
  echo ""
  warn "IMPORTANT: Add this public key to .sops.yaml on the main machine,"
  warn "then re-encrypt secrets: sops updatekeys secrets/aws-credentials.enc"
  warn "Without this, sops-nix secrets will not decrypt on this machine."
}

# --------------------------------------------------------------------------- #
# Add machine to flake.nix
# --------------------------------------------------------------------------- #

add_machine() {
  step "Configuring machine"
  cd "$REPO_DIR"

  local hostname
  hostname=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
  info "Detected hostname: $hostname"

  read -rp "Use '$hostname' as the machine name? (Y/n) " reply
  if [[ "$reply" =~ ^[Nn]$ ]]; then
    read -rp "Enter machine name: " hostname
  fi

  # Check if machine already exists in flake.nix
  if grep -q "darwinConfigurations.\"$hostname\"" flake.nix; then
    success "Machine '$hostname' already in flake.nix"
    echo "$hostname"
    return 0
  fi

  info "Adding '$hostname' to flake.nix..."

  # Insert a new darwinConfigurations block before the closing '};' of the output set.
  # We copy the pattern from existing machines (Darth, Grogu, Renova).
  local new_block
  new_block=$(cat <<NIXEOF
      darwinConfigurations."$hostname" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
                  home-manager.users."\\\${username}" = homeconfig;
               }
         ];
      };
NIXEOF
)

  # Find the last darwinConfigurations block and append after it
  # Use python for reliable multi-line insertion (sed is fragile for this)
  python3 -c "
import re, sys

with open('flake.nix', 'r') as f:
    content = f.read()

# Find the last '};' before the final '};' of outputs
# Pattern: insert before the final closing of the outputs set
marker = '   };\\n}'
insertion = '''      darwinConfigurations.\"$hostname\" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  home-manager.backupFileExtension = \"backup\";
                  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
                  home-manager.users.\"\\\${username}\" = homeconfig;
               }
         ];
      };
'''

replacement = insertion + '   };\\n}'
content = content.replace(marker, replacement, 1)

with open('flake.nix', 'w') as f:
    f.write(content)

print('OK')
" && success "Added '$hostname' to flake.nix" || {
    fail "Auto-add failed. Add the machine config to flake.nix manually."
    fail "Copy any existing darwinConfigurations block and change the name to '$hostname'."
  }

  echo "$hostname"
}

# --------------------------------------------------------------------------- #
# Build and activate
# --------------------------------------------------------------------------- #

build() {
  local hostname="$1"
  step "Building configuration for '$hostname'"
  cd "$REPO_DIR"

  info "This will take a while on first run (downloading all packages)..."

  if sudo darwin-rebuild switch --flake "$REPO_DIR#$hostname"; then
    success "Configuration built and activated!"
  else
    fail "Build failed. Check errors above."
    exit 1
  fi
}

# --------------------------------------------------------------------------- #
# Post-install
# --------------------------------------------------------------------------- #

post_install() {
  step "Post-install"

  # WezTerm terminfo
  if command_exists wezterm; then
    local tempfile
    tempfile=$(mktemp)
    if curl -so "$tempfile" https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo 2>/dev/null; then
      tic -x -o ~/.terminfo "$tempfile" 2>/dev/null
      rm "$tempfile"
      success "WezTerm terminfo installed"
    fi
  fi

  echo ""
  success "Bootstrap complete!"
  echo ""
  info "To rebuild after changes:"
  info "  sudo darwin-rebuild switch --flake ~/.config/nix"
  echo ""
  info "To update packages:"
  info "  cd ~/.config/nix && nix flake update"
  echo ""
  warn "If sops-nix secrets are needed, add this machine's age public key"
  warn "to .sops.yaml on the main machine and re-encrypt."
  echo ""
  info "Open a new terminal to load all changes."
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

main() {
  echo ""
  echo -e "${BOLD}Nix-Darwin Bootstrap${NC}"
  echo -e "Setting up macOS with nix-darwin + Home Manager"
  echo ""

  preflight
  install_nix
  install_homebrew
  clone_repo
  unlock_gitcrypt
  setup_age_key

  local hostname
  hostname=$(add_machine)

  build "$hostname"
  post_install
}

main "$@"
