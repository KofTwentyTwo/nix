#!/usr/bin/env bash
# git-log-all.sh - Show recent commits for all git repos in current directory
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -n, --count N  Number of commits to show (default: 3)"
    echo "  -h, --help     Show this help"
    exit 1
}

COUNT=3
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--count) COUNT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        repo_name="${dir%/}"
        branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "detached")

        echo -e "${BOLD}${repo_name}${NC} ${DIM}(${branch})${NC}"

        git -C "$dir" log --oneline --no-decorate -n "$COUNT" 2>/dev/null | while read -r line; do
            hash="${line%% *}"
            msg="${line#* }"
            echo -e "  ${YELLOW}${hash}${NC} ${msg}"
        done

        echo ""
    fi
done
