#!/usr/bin/env bash
# git-status-all.sh - Check status of all git repos in current directory
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Track stats
declare -a dirty_repos=()
clean_count=0
dirty_count=0

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
        cd "$dir"

        repo_name="${dir%/}"
        is_dirty=false
        dirty_details=""
        sync_status=""

        # Check for uncommitted changes
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
            unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
            untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
            dirty_details="staged:${staged} unstaged:${unstaged} untracked:${untracked}"
            is_dirty=true
        fi

        # Check for unpushed commits
        upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")

        if [[ -n "$upstream" ]]; then
            ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "0")
            behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")

            if [[ "$ahead" -gt 0 ]]; then
                sync_status="${sync_status} ${YELLOW}+${ahead} ahead${NC}"
            fi
            if [[ "$behind" -gt 0 ]]; then
                sync_status="${sync_status} ${BLUE}-${behind} behind${NC}"
            fi
        else
            sync_status=" ${YELLOW}(no upstream)${NC}"
        fi

        # Build and print status line
        if [[ "$is_dirty" == true ]]; then
            printf "%-${max_len}s  ${RED}DIRTY${NC}  (%s)%b\n" "$repo_name" "$dirty_details" "$sync_status"
            ((dirty_count++)) || true
            dirty_repos+=("${repo_name}|${dirty_details}${sync_status}")
        else
            printf "%-${max_len}s  ${GREEN}CLEAN${NC}%b\n" "$repo_name" "$sync_status"
            ((clean_count++)) || true
        fi

        cd ..
    fi
done

# Print summary
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Clean: ${GREEN}${clean_count}${NC}  Dirty: ${RED}${dirty_count}${NC}"

if [[ ${#dirty_repos[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}Dirty Repos:${NC}"
    for entry in "${dirty_repos[@]}"; do
        repo="${entry%%|*}"
        details="${entry#*|}"
        printf "  %-${max_len}s  %b\n" "$repo" "$details"
    done
fi
