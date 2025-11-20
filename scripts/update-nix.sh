#!/usr/bin/env bash
# Update Nix flake and rebuild configuration
# Usage: update-nix.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}Updating Nix flake...${NC}"
nix flake update ~/.config/nix

echo -e "${CYAN}Rebuilding configuration...${NC}"
darwin-rebuild switch --flake ~/.config/nix

echo -e "${GREEN}✓ Update complete!${NC}"

