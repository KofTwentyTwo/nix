#!/usr/bin/env bash
# git-sync-all.sh - Morning sync: fetch, switch to latest branch, pull all repos
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

# Files/patterns to silently discard when dirty (glob patterns)
IGNORED_PATTERNS=(
    ".idea/"
    "*.iml"
    ".claude/"
    ".claude/settings.local.json"
    ".vscode/"
    ".DS_Store"
    "*.swp"
    "*.swo"
    ".envrc"
    ".direnv/"
)

usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Syncs all git repos in the current directory with their remotes."
    echo "For each repo: fetches, switches to the most recently pushed branch,"
    echo "and pulls latest changes. Handles dirty working trees gracefully."
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show what would happen without making changes"
    echo "  -e, --email STR  Override git committer email for branch detection"
    echo "  -h, --help       Show this help"
    exit 0
}

DRY_RUN=false
EMAIL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true; shift ;;
        -e|--email) EMAIL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Resolve email: flag > git config > fallback
if [[ -z "$EMAIL" ]]; then
    EMAIL=$(git config user.email 2>/dev/null || echo "")
fi
if [[ -z "$EMAIL" ]]; then
    echo -e "${RED}Could not determine git email. Use --email to specify.${NC}"
    exit 1
fi

# Track stats
synced=0
uptodate=0
skipped=0
failed=0

# Build a single grep pattern from IGNORED_PATTERNS for matching dirty files
is_only_ignored_files() {
    local repo_dir="$1"
    local dirty_files
    dirty_files=$(git -C "$repo_dir" status --porcelain 2>/dev/null)

    if [[ -z "$dirty_files" ]]; then
        return 1  # not dirty at all
    fi

    while IFS= read -r line; do
        # Extract the file path (skip the 2-char status prefix and space)
        local filepath="${line:3}"
        # Remove leading/trailing quotes if present
        filepath="${filepath#\"}"
        filepath="${filepath%\"}"

        local matched=false
        for pattern in "${IGNORED_PATTERNS[@]}"; do
            # Check if filepath starts with a directory pattern
            if [[ "$pattern" == */ ]] && [[ "$filepath" == ${pattern}* ]]; then
                matched=true
                break
            fi
            # Check glob match on the basename or full path
            # shellcheck disable=SC2254
            if [[ "$(basename "$filepath")" == ${pattern} ]] || [[ "$filepath" == ${pattern} ]]; then
                matched=true
                break
            fi
        done

        if [[ "$matched" == false ]]; then
            return 1  # found a file not in the ignore list
        fi
    done <<< "$dirty_files"

    return 0  # all dirty files are ignorable
}

discard_ignored_files() {
    local repo_dir="$1"
    local dirty_files
    dirty_files=$(git -C "$repo_dir" status --porcelain 2>/dev/null)

    while IFS= read -r line; do
        local status="${line:0:2}"
        local filepath="${line:3}"
        filepath="${filepath#\"}"
        filepath="${filepath%\"}"

        local matched=false
        for pattern in "${IGNORED_PATTERNS[@]}"; do
            if [[ "$pattern" == */ ]] && [[ "$filepath" == ${pattern}* ]]; then
                matched=true
                break
            fi
            # shellcheck disable=SC2254
            if [[ "$(basename "$filepath")" == ${pattern} ]] || [[ "$filepath" == ${pattern} ]]; then
                matched=true
                break
            fi
        done

        if [[ "$matched" == true ]]; then
            if [[ "$status" == "??" ]]; then
                # Untracked: just remove it
                rm -rf "${repo_dir}/${filepath}"
            else
                # Tracked: restore from index
                git -C "$repo_dir" checkout -- "$filepath" 2>/dev/null
            fi
        fi
    done <<< "$dirty_files"
}

# Find the most recently pushed branch by this user on the remote
find_latest_remote_branch() {
    local repo_dir="$1"
    local user_email="$2"

    # Get all remote branches sorted by committer date (most recent first)
    # Filter to commits by this user's email
    git -C "$repo_dir" for-each-ref \
        --sort=-committerdate \
        --format='%(committerdate:iso8601) %(committeremail) %(refname:short)' \
        refs/remotes/origin/ 2>/dev/null \
    | while IFS= read -r line; do
        local email_field
        email_field=$(echo "$line" | awk '{print $4}')
        # Strip angle brackets
        email_field="${email_field#<}"
        email_field="${email_field%>}"

        if [[ "$email_field" == "$user_email" ]]; then
            # Return the branch name without the origin/ prefix
            local branch
            branch=$(echo "$line" | awk '{print $5}')
            branch="${branch#origin/}"
            # Skip HEAD
            if [[ "$branch" != "HEAD" ]]; then
                echo "$branch"
                return 0
            fi
        fi
    done
}

# Find max repo name length for alignment
max_len=0
for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        name="${dir%/}"
        (( ${#name} > max_len )) && max_len=${#name}
    fi
done

if [[ "$max_len" -eq 0 ]]; then
    echo -e "${YELLOW}No git repositories found in current directory.${NC}"
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BOLD}=== Dry Run (no changes will be made) ===${NC}"
    echo ""
fi

echo -e "${DIM}Syncing as: ${EMAIL}${NC}"
echo ""

for dir in */; do
    if [[ -d "${dir}.git" ]]; then
        repo_name="${dir%/}"

        # Step 1: Fetch
        printf "%-${max_len}s  " "$repo_name"

        if [[ "$DRY_RUN" == false ]]; then
            if ! git -C "$dir" fetch --all --prune --quiet 2>/dev/null; then
                echo -e "${RED}FAILED${NC} (fetch error)"
                ((failed++))
                continue
            fi
        fi

        # Step 2: Determine target branch
        latest_branch=$(find_latest_remote_branch "$dir" "$EMAIL")
        current_branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

        if [[ -z "$latest_branch" ]]; then
            # No branch found by this user; fall back to current branch
            latest_branch="$current_branch"
        fi

        needs_switch=false
        if [[ "$current_branch" != "$latest_branch" ]]; then
            needs_switch=true
        fi

        # Step 3: Handle dirty working tree
        is_dirty=false
        if [[ -n $(git -C "$dir" status --porcelain 2>/dev/null) ]]; then
            is_dirty=true
        fi

        did_stash=false
        if [[ "$is_dirty" == true ]]; then
            if is_only_ignored_files "$dir"; then
                # All dirty files are ignorable; discard them
                if [[ "$DRY_RUN" == false ]]; then
                    discard_ignored_files "$dir"
                fi
            else
                # Real changes; stash them
                if [[ "$DRY_RUN" == false ]]; then
                    git -C "$dir" stash push --quiet --include-untracked -m "git-sync-all auto-stash" 2>/dev/null
                fi
                did_stash=true
            fi
        fi

        # Step 4: Switch branch if needed
        if [[ "$needs_switch" == true ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                if ! git -C "$dir" checkout "$latest_branch" --quiet 2>/dev/null; then
                    echo -e "${RED}FAILED${NC} (checkout ${latest_branch})"
                    # Pop stash if we made one
                    if [[ "$did_stash" == true ]]; then
                        git -C "$dir" stash pop --quiet 2>/dev/null
                    fi
                    ((failed++))
                    continue
                fi
            fi
        fi

        # Step 5: Pull
        if [[ "$DRY_RUN" == true ]]; then
            # Dry run output
            status_parts=""
            if [[ "$needs_switch" == true ]]; then
                status_parts="${CYAN}${current_branch} -> ${latest_branch}${NC}"
            else
                status_parts="${DIM}${current_branch}${NC}"
            fi
            if [[ "$did_stash" == true ]]; then
                status_parts="${status_parts} ${YELLOW}(would stash)${NC}"
            fi
            echo -e "$status_parts"
            ((uptodate++))
            continue
        fi

        # Check if there are upstream commits to pull
        upstream=$(git -C "$dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
        if [[ -z "$upstream" ]]; then
            # No upstream tracking; just report the branch state
            status_msg="${DIM}${current_branch}${NC} ${BLUE}(no upstream)${NC}"
            if [[ "$needs_switch" == true ]]; then
                status_msg="${CYAN}${current_branch} -> ${latest_branch}${NC} ${BLUE}(no upstream)${NC}"
            fi
            echo -e "$status_msg"
            if [[ "$did_stash" == true ]]; then
                git -C "$dir" stash pop --quiet 2>/dev/null
            fi
            ((skipped++))
            continue
        fi

        behind=$(git -C "$dir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")

        output=$(git -C "$dir" pull --quiet 2>&1)
        pull_ok=$?

        # Step 6: Pop stash
        stash_conflict=false
        if [[ "$did_stash" == true ]]; then
            if ! git -C "$dir" stash pop --quiet 2>/dev/null; then
                stash_conflict=true
            fi
        fi

        # Step 7: Report
        if [[ $pull_ok -eq 0 ]]; then
            status_parts=""

            if [[ "$needs_switch" == true ]]; then
                status_parts="${CYAN}${current_branch} -> ${latest_branch}${NC} "
            fi

            if [[ "$behind" -gt 0 ]]; then
                status_parts="${status_parts}${GREEN}pulled ${behind} commit(s)${NC}"
                ((synced++))
            else
                status_parts="${status_parts}${GREEN}up to date${NC}"
                ((uptodate++))
            fi

            if [[ "$did_stash" == true ]]; then
                if [[ "$stash_conflict" == true ]]; then
                    status_parts="${status_parts} ${RED}(stash conflict!)${NC}"
                else
                    status_parts="${status_parts} ${YELLOW}(stash restored)${NC}"
                fi
            fi

            echo -e "$status_parts"
        else
            echo -e "${RED}FAILED${NC} (pull error)"
            if [[ "$did_stash" == true ]] && [[ "$stash_conflict" == false ]]; then
                # stash was already popped or not; if pop failed we already noted it
                :
            fi
            ((failed++))
        fi
    fi
done

# Summary
echo ""
echo -e "${BOLD}=== Summary ===${NC}"
echo -e "Synced: ${GREEN}${synced}${NC}  Up-to-date: ${GREEN}${uptodate}${NC}  Skipped: ${YELLOW}${skipped}${NC}  Failed: ${RED}${failed}${NC}"
