#!/usr/bin/env bash
# git-clone-all.sh - Clone all repos from a GitHub organization
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") <org-name> [options]"
    echo ""
    echo "Options:"
    echo "  -f, --fetch    Fetch updates for existing repos"
    echo "  --https        Use HTTPS URLs (default: SSH)"
    echo "  -h, --help     Show this help"
    exit 1
}

# Defaults
ORG=""
FETCH_EXISTING=false
USE_SSH=true

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fetch) FETCH_EXISTING=true; shift ;;
        --https) USE_SSH=false; shift ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) ORG="$1"; shift ;;
    esac
done

if [[ -z "$ORG" ]]; then
    echo -e "${RED}Error: Organization name required${NC}"
    usage
fi

# Check gh is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is required${NC}"
    exit 1
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI. Run 'gh auth login'${NC}"
    exit 1
fi

echo -e "${BOLD}Fetching repos for ${BLUE}${ORG}${NC}${BOLD}...${NC}"

# Get all repos (handles pagination automatically)
if [[ "$USE_SSH" == true ]]; then
    repos=$(gh repo list "$ORG" --limit 1000 --json name,sshUrl --jq '.[] | "\(.name)|\(.sshUrl)"' 2>/dev/null)
else
    repos=$(gh repo list "$ORG" --limit 1000 --json name,url --jq '.[] | "\(.name)|\(.url)"' 2>/dev/null)
fi

if [[ -z "$repos" ]]; then
    echo -e "${RED}No repos found for org '${ORG}' (or no access)${NC}"
    exit 1
fi

# Track stats
cloned=0
existed=0
fetched=0
failed=0

# Find max name length
max_len=0
while IFS='|' read -r name _; do
    (( ${#name} > max_len )) && max_len=${#name}
done <<< "$repos"

echo ""

while IFS='|' read -r name url; do
    if [[ -d "$name" ]]; then
        if [[ "$FETCH_EXISTING" == true ]]; then
            printf "%-${max_len}s  ${BLUE}EXISTS${NC}  fetching... " "$name"
            if git -C "$name" fetch --all --quiet 2>/dev/null; then
                echo -e "${GREEN}done${NC}"
                ((fetched++))
            else
                echo -e "${RED}failed${NC}"
            fi
        else
            printf "%-${max_len}s  ${BLUE}EXISTS${NC}\n" "$name"
        fi
        ((existed++))
    else
        printf "%-${max_len}s  ${YELLOW}CLONING${NC}... " "$name"
        if git clone --quiet "$url" 2>/dev/null; then
            echo -e "${GREEN}done${NC}"
            ((cloned++))
        else
            echo -e "${RED}failed${NC}"
            ((failed++))
        fi
    fi
done <<< "$repos"

# Summary
total=$((cloned + existed))
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Total repos: ${BOLD}${total}${NC}"
echo -e "  Cloned:  ${GREEN}${cloned}${NC}"
echo -e "  Existed: ${BLUE}${existed}${NC}"
[[ "$FETCH_EXISTING" == true ]] && echo -e "  Fetched: ${BLUE}${fetched}${NC}"
[[ "$failed" -gt 0 ]] && echo -e "  Failed:  ${RED}${failed}${NC}"
