#!/usr/bin/env bash
# Fix Git Remote URL
# ==================
# Updates the remote URL when a repository has moved on GitHub.
#
# Usage:
#   fix-git-remote.sh [remote-name]
#
# If no remote name is provided, defaults to 'origin'

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

remote_name="${1:-origin}"

# Check if we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo -e "${RED}✗${NC} Not in a git repository" >&2
  exit 1
fi

# Get current remote URL
current_url=$(git remote get-url "$remote_name" 2>/dev/null || echo "")

if [[ -z "$current_url" ]]; then
  echo -e "${RED}✗${NC} Remote '$remote_name' not found" >&2
  echo -e "${CYAN}Available remotes:${NC}"
  git remote -v
  exit 1
fi

echo -e "${CYAN}Current remote URL:${NC} $current_url"

# Try to fetch and see if GitHub tells us the new location
echo -e "${CYAN}Checking for repository redirect...${NC}"
new_url=$(git ls-remote --get-url "$remote_name" 2>&1 | grep -i "moved\|new location" || true)

# If git fetch shows a redirect message, extract the new URL
if git fetch "$remote_name" 2>&1 | grep -q "new location"; then
  # Try to get the new URL from git's redirect message
  fetch_output=$(git fetch "$remote_name" 2>&1 || true)
  new_url=$(echo "$fetch_output" | grep -oP 'git@github\.com:[^\s]+\.git' | head -1 || echo "")
  
  if [[ -n "$new_url" ]] && [[ "$new_url" != "$current_url" ]]; then
    echo -e "${YELLOW}⚠${NC} Repository has moved!"
    echo -e "${CYAN}New location:${NC} $new_url"
    echo ""
    read -p "Update remote URL? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      git remote set-url "$remote_name" "$new_url"
      echo -e "${GREEN}✓${NC} Remote URL updated to: $new_url"
    else
      echo -e "${YELLOW}Update cancelled${NC}"
    fi
  else
    echo -e "${CYAN}ℹ${NC} No redirect detected or URL unchanged"
  fi
else
  echo -e "${CYAN}ℹ${NC} No redirect message found"
  echo -e "${CYAN}ℹ${NC} If you know the new URL, update manually with:"
  echo -e "  ${YELLOW}git remote set-url $remote_name <new-url>${NC}"
fi

