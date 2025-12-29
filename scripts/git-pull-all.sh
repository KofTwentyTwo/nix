#!/usr/bin/env bash
# git-pull-all.sh - Pull updates for all git repos in current directory
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -f, --force    Pull even if repo has uncommitted changes"
    echo "  -h, --help     Show this help"
    exit 1
}

FORCE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force) FORCE=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Track stats
pulled=0
skipped=0
failed=0
uptodate=0

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

        # Check for uncommitted changes
        if [[ -n $(git -C "$dir" status --porcelain 2>/dev/null) ]] && [[ "$FORCE" == false ]]; then
            printf "%-${max_len}s  ${YELLOW}SKIPPED${NC} (dirty)\n" "$repo_name"
            ((skipped++))
            continue
        fi

        # Check if upstream exists
        upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
        if [[ -z "$upstream" ]]; then
            printf "%-${max_len}s  ${BLUE}SKIPPED${NC} (no upstream)\n" "$repo_name"
            ((skipped++))
            continue
        fi

        printf "%-${max_len}s  pulling... " "$repo_name"

        output=$(git -C "$dir" pull --quiet 2>&1)
        if [[ $? -eq 0 ]]; then
            if [[ "$output" == *"Already up to date"* ]] || [[ -z "$output" ]]; then
                echo -e "${GREEN}up to date${NC}"
                ((uptodate++))
            else
                echo -e "${GREEN}updated${NC}"
                ((pulled++))
            fi
        else
            echo -e "${RED}failed${NC}"
            ((failed++))
        fi
    fi
done

# Summary
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Updated: ${GREEN}${pulled}${NC}  Up-to-date: ${GREEN}${uptodate}${NC}  Skipped: ${YELLOW}${skipped}${NC}  Failed: ${RED}${failed}${NC}"
