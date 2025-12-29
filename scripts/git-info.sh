#!/usr/bin/env bash
# git-info.sh - Show comprehensive info about a git repository
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

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "${RED}Not a git repository${NC}"
    exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")

echo -e "${BOLD}=== ${repo_name} ===${NC}"
echo ""

# Current branch/state
echo -e "${BOLD}Branch:${NC}"
branch=$(git branch --show-current)
if [[ -z "$branch" ]]; then
    commit=$(git rev-parse --short HEAD)
    echo -e "  ${YELLOW}(detached HEAD at ${commit})${NC}"
else
    echo -e "  ${CYAN}${branch}${NC}"
fi

# Remote info
echo ""
echo -e "${BOLD}Remotes:${NC}"
while IFS= read -r remote; do
    [[ -z "$remote" ]] && continue
    name="${remote%%	*}"
    url="${remote#*	}"
    url="${url% (*}"
    type="${remote##* }"
    if [[ "$type" == "(fetch)" ]]; then
        echo -e "  ${GREEN}${name}${NC}: ${url}"
    fi
done < <(git remote -v)

# Upstream tracking
echo ""
echo -e "${BOLD}Tracking:${NC}"
upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null || echo "")
if [[ -n "$upstream" ]]; then
    ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "0")
    behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")
    echo -e "  Upstream: ${BLUE}${upstream}${NC}"
    if [[ "$ahead" -gt 0 ]] || [[ "$behind" -gt 0 ]]; then
        echo -e "  Status: ${YELLOW}+${ahead} ahead${NC}, ${BLUE}-${behind} behind${NC}"
    else
        echo -e "  Status: ${GREEN}up to date${NC}"
    fi
else
    echo -e "  ${DIM}No upstream configured${NC}"
fi

# Working tree status
echo ""
echo -e "${BOLD}Working Tree:${NC}"
staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

if [[ "$staged" -eq 0 ]] && [[ "$unstaged" -eq 0 ]] && [[ "$untracked" -eq 0 ]]; then
    echo -e "  ${GREEN}Clean${NC}"
else
    [[ "$staged" -gt 0 ]] && echo -e "  Staged:    ${GREEN}${staged}${NC}"
    [[ "$unstaged" -gt 0 ]] && echo -e "  Unstaged:  ${YELLOW}${unstaged}${NC}"
    [[ "$untracked" -gt 0 ]] && echo -e "  Untracked: ${RED}${untracked}${NC}"
fi

# Stashes
stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
if [[ "$stash_count" -gt 0 ]]; then
    echo -e "  Stashes:   ${BLUE}${stash_count}${NC}"
fi

# Last commit
echo ""
echo -e "${BOLD}Last Commit:${NC}"
git log -1 --format="  ${YELLOW}%h${NC} %s ${DIM}(%cr by %an)${NC}" 2>/dev/null

# Branches summary
echo ""
echo -e "${BOLD}Branches:${NC}"
local_count=$(git branch | wc -l | tr -d ' ')
remote_count=$(git branch -r 2>/dev/null | wc -l | tr -d ' ')
echo -e "  Local: ${local_count}, Remote: ${remote_count}"

# Tags
tag_count=$(git tag | wc -l | tr -d ' ')
if [[ "$tag_count" -gt 0 ]]; then
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    echo ""
    echo -e "${BOLD}Tags:${NC} ${tag_count} total"
    [[ -n "$latest_tag" ]] && echo -e "  Latest: ${CYAN}${latest_tag}${NC}"
fi

# Repo path
echo ""
echo -e "${BOLD}Path:${NC}"
echo -e "  ${DIM}${repo_root}${NC}"

# Links section
origin_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ -n "$origin_url" ]]; then
    # Convert git URL to web URL
    web_url=""
    if [[ "$origin_url" =~ github\.com ]]; then
        # Handle SSH: git@github.com:org/repo.git
        # Handle HTTPS: https://github.com/org/repo.git
        web_url=$(echo "$origin_url" | sed -E 's|git@github\.com:|https://github.com/|; s|\.git$||')
    elif [[ "$origin_url" =~ gitlab\.com ]]; then
        web_url=$(echo "$origin_url" | sed -E 's|git@gitlab\.com:|https://gitlab.com/|; s|\.git$||')
    elif [[ "$origin_url" =~ bitbucket\.org ]]; then
        web_url=$(echo "$origin_url" | sed -E 's|git@bitbucket\.org:|https://bitbucket.org/|; s|\.git$||')
    fi

    if [[ -n "$web_url" ]]; then
        echo ""
        echo -e "${BOLD}Links:${NC}"
        echo -e "  Repo:     ${BLUE}${web_url}${NC}"

        # CircleCI - check if config exists and construct URL
        if [[ -f "${repo_root}/.circleci/config.yml" ]] || [[ -f "${repo_root}/.circleci/config.yaml" ]]; then
            # Extract org/repo from web_url
            if [[ "$web_url" =~ github\.com/([^/]+)/([^/]+) ]]; then
                org="${BASH_REMATCH[1]}"
                repo="${BASH_REMATCH[2]}"
                circleci_url="https://app.circleci.com/pipelines/github/${org}/${repo}"
                echo -e "  CircleCI: ${BLUE}${circleci_url}${NC}"
            fi
        fi
    fi
fi
