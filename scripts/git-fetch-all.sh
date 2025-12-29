#!/usr/bin/env bash
# git-fetch-all.sh - Fetch updates for all git repos in current directory
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# Track stats
success=0
failed=0

# Find max repo name length
max_len=0
for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        name="${dir%/}"
        (( ${#name} > max_len )) && max_len=${#name}
    fi
done

for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        repo_name="${dir%/}"
        printf "%-${max_len}s  fetching... " "$repo_name"

        if git -C "$dir" fetch --all --prune --quiet 2>/dev/null; then
            # Check if there are new commits
            upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
            if [[ -n "$upstream" ]]; then
                behind=$(git -C "$dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")
                if [[ "$behind" -gt 0 ]]; then
                    echo -e "${GREEN}done${NC} ${YELLOW}(${behind} new)${NC}"
                else
                    echo -e "${GREEN}done${NC}"
                fi
            else
                echo -e "${GREEN}done${NC}"
            fi
            ((success++))
        else
            echo -e "${RED}failed${NC}"
            ((failed++))
        fi
    fi
done

# Summary
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Fetched: ${GREEN}${success}${NC}  Failed: ${RED}${failed}${NC}"
