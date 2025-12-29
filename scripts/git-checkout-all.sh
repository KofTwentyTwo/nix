#!/usr/bin/env bash
# git-checkout-all.sh - Checkout a branch in all repos that have it
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") <branch-name> [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force    Checkout even if repo has uncommitted changes"
    echo "  -h, --help     Show this help"
    exit 1
}

BRANCH=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force) FORCE=true; shift ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) BRANCH="$1"; shift ;;
    esac
done

if [[ -z "$BRANCH" ]]; then
    echo -e "${RED}Error: Branch name required${NC}"
    usage
fi

# Track stats
checked_out=0
skipped_dirty=0
skipped_no_branch=0
already_on=0
failed=0

# Find max repo name length
max_len=0
for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        name="${dir%/}"
        (( ${#name} > max_len )) && max_len=${#name}
    fi
done

echo -e "${BOLD}Checking out '${BLUE}${BRANCH}${NC}${BOLD}' in all repos...${NC}"
echo ""

for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        repo_name="${dir%/}"

        # Check if branch exists (local or remote)
        if ! git -C "$dir" show-ref --verify --quiet "refs/heads/${BRANCH}" 2>/dev/null && \
           ! git -C "$dir" show-ref --verify --quiet "refs/remotes/origin/${BRANCH}" 2>/dev/null; then
            printf "%-${max_len}s  ${BLUE}SKIPPED${NC} (no branch)\n" "$repo_name"
            ((skipped_no_branch++))
            continue
        fi

        # Check current branch
        current=$(git -C "$dir" branch --show-current 2>/dev/null)
        if [[ "$current" == "$BRANCH" ]]; then
            printf "%-${max_len}s  ${GREEN}already on${NC}\n" "$repo_name"
            ((already_on++))
            continue
        fi

        # Check for uncommitted changes
        if [[ -n $(git -C "$dir" status --porcelain 2>/dev/null) ]] && [[ "$FORCE" == false ]]; then
            printf "%-${max_len}s  ${YELLOW}SKIPPED${NC} (dirty)\n" "$repo_name"
            ((skipped_dirty++))
            continue
        fi

        printf "%-${max_len}s  checking out... " "$repo_name"

        if git -C "$dir" checkout "$BRANCH" --quiet 2>/dev/null; then
            echo -e "${GREEN}done${NC}"
            ((checked_out++))
        else
            echo -e "${RED}failed${NC}"
            ((failed++))
        fi
    fi
done

# Summary
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Checked out: ${GREEN}${checked_out}${NC}  Already on: ${GREEN}${already_on}${NC}"
echo -e "Skipped (dirty): ${YELLOW}${skipped_dirty}${NC}  Skipped (no branch): ${BLUE}${skipped_no_branch}${NC}"
[[ "$failed" -gt 0 ]] && echo -e "Failed: ${RED}${failed}${NC}"
