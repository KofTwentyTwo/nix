#!/usr/bin/env bash
# GitOps Feature Branch Publisher
# ================================
# Publishes a feature branch for testing by creating and pushing a tag.
# Only works on feature branches (branches starting with 'feature/').
#
# Usage:
#   gitops-publish.sh
#
# What it does:
#   1. Verifies you're on a feature branch
#   2. Gets the current short commit hash
#   3. Checks if tag exists and deletes it if present
#   4. Creates tag: publish-{short-hash}
#   5. Pushes the tag to trigger GitOps workflow

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Get current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ -z "$current_branch" ]]; then
  echo -e "${RED}✗${NC} Not in a git repository" >&2
  exit 1
fi

# Check if we're on a feature branch
if [[ ! "$current_branch" =~ ^feature/ ]]; then
  echo -e "${RED}✗${NC} Not on a feature branch (current: ${YELLOW}$current_branch${NC})" >&2
  echo -e "${CYAN}ℹ${NC} This script only works on branches starting with 'feature/'" >&2
  exit 1
fi

echo -e "${CYAN}Branch:${NC} ${GREEN}$current_branch${NC}"

# Get short commit hash
short_hash=$(git rev-parse --short HEAD)
if [[ -z "$short_hash" ]]; then
  echo -e "${RED}✗${NC} Failed to get commit hash" >&2
  exit 1
fi

echo -e "${CYAN}Commit:${NC} ${GREEN}$short_hash${NC}"

# Construct tag name
tag_name="publish-${short_hash}"

# Check if tag already exists
if git rev-parse "$tag_name" >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠${NC} Tag ${BLUE}$tag_name${NC} already exists"
  
  # Check if tag exists on remote
  if git ls-remote --tags origin "$tag_name" >/dev/null 2>&1; then
    echo -e "${CYAN}Deleting remote tag...${NC}"
    git push origin --delete "$tag_name" || {
      echo -e "${RED}✗${NC} Failed to delete remote tag" >&2
      exit 1
    }
  fi
  
  # Delete local tag
  echo -e "${CYAN}Deleting local tag...${NC}"
  git tag -d "$tag_name" || {
    echo -e "${YELLOW}⚠${NC} Local tag doesn't exist (that's okay)" >&2
  }
  
  echo -e "${GREEN}✓${NC} Tag deleted, will recreate"
fi

# Create annotated tag
echo -e "${CYAN}Creating tag:${NC} ${BLUE}$tag_name${NC}"
if git tag -a "$tag_name" -m "Publish $short_hash"; then
  echo -e "${GREEN}✓${NC} Tag created locally"
else
  echo -e "${RED}✗${NC} Failed to create tag" >&2
  exit 1
fi

# Push tag to remote
echo -e "${CYAN}Pushing tag to origin...${NC}"
if git push origin "$tag_name"; then
  echo -e "${GREEN}✓${NC} Tag pushed successfully"
  echo ""
  echo -e "${GREEN}${BOLD}✅ Published!${NC}"
  echo -e "${CYAN}Tag:${NC} ${BLUE}$tag_name${NC}"
  echo -e "${CYAN}Branch:${NC} ${GREEN}$current_branch${NC}"
  echo -e "${CYAN}Commit:${NC} ${GREEN}$short_hash${NC}"
else
  echo -e "${RED}✗${NC} Failed to push tag" >&2
  exit 1
fi

