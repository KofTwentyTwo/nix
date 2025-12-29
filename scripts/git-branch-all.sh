#!/usr/bin/env bash
# git-branch-all.sh - Show current branch for all git repos in current directory
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Find max repo name length
max_len=0
for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        name="${dir%/}"
        (( ${#name} > max_len )) && max_len=${#name}
    fi
done

# Track branches for summary
declare -A branch_counts

for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        repo_name="${dir%/}"
        branch=$(git -C "$dir" branch --show-current 2>/dev/null)

        # Handle detached HEAD
        if [[ -z "$branch" ]]; then
            commit=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
            printf "%-${max_len}s  ${YELLOW}(detached: ${commit})${NC}\n" "$repo_name"
            ((branch_counts["(detached)"]++)) || branch_counts["(detached)"]=1
        else
            # Color main/master differently
            if [[ "$branch" == "main" || "$branch" == "master" ]]; then
                printf "%-${max_len}s  ${GREEN}%s${NC}\n" "$repo_name" "$branch"
            else
                printf "%-${max_len}s  ${CYAN}%s${NC}\n" "$repo_name" "$branch"
            fi
            ((branch_counts["$branch"]++)) || branch_counts["$branch"]=1
        fi
    fi
done

# Summary
echo ""
echo -e "${BOLD}=== Branch Summary ===${NC}"
for branch in "${!branch_counts[@]}"; do
    count="${branch_counts[$branch]}"
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
        echo -e "  ${GREEN}${branch}${NC}: ${count}"
    elif [[ "$branch" == "(detached)" ]]; then
        echo -e "  ${YELLOW}${branch}${NC}: ${count}"
    else
        echo -e "  ${CYAN}${branch}${NC}: ${count}"
    fi
done | sort
