#!/usr/bin/env bash
# git-help.sh - Show all custom git commands and aliases
set -uo pipefail

# Colors
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${BOLD}=== Git Batch Commands ===${NC}"
echo ""
echo -e "  ${CYAN}gsa${NC}   ${DIM}git-status-all.sh${NC}     Check status of all repos in current dir"
echo -e "  ${CYAN}gclo${NC}  ${DIM}git-clone-all.sh${NC}      Clone all repos from a GitHub org"
echo -e "  ${CYAN}gfa${NC}   ${DIM}git-fetch-all.sh${NC}      Fetch updates for all repos"
echo -e "  ${CYAN}gpa${NC}   ${DIM}git-pull-all.sh${NC}       Pull all repos (skips dirty)"
echo -e "  ${CYAN}gba${NC}   ${DIM}git-branch-all.sh${NC}     Show current branch for all repos"
echo -e "  ${CYAN}gcoa${NC}  ${DIM}git-checkout-all.sh${NC}   Checkout branch in all repos"
echo -e "  ${CYAN}gla${NC}   ${DIM}git-log-all.sh${NC}        Show recent commits for all repos"
echo -e "  ${CYAN}gi${NC}    ${DIM}git-info.sh${NC}           Show comprehensive repo info + links"
echo ""
echo -e "${BOLD}=== Git Shortcuts ===${NC}"
echo ""
echo -e "  ${GREEN}gc${NC}    ${DIM}git cz c${NC}              Commit using commitizen"
echo -e "  ${GREEN}gt${NC}    ${DIM}gitops-publish.sh${NC}     GitOps: publish feature branch tag"
echo ""
echo -e "${BOLD}=== Usage Examples ===${NC}"
echo ""
echo -e "  ${YELLOW}gclo qrun-io${NC}          Clone all QRun-IO repos (SSH default)"
echo -e "  ${YELLOW}gclo org -f${NC}           Clone org repos, fetch existing"
echo -e "  ${YELLOW}gclo org --https${NC}      Clone using HTTPS instead of SSH"
echo -e "  ${YELLOW}gpa${NC}                   Pull all clean repos"
echo -e "  ${YELLOW}gcoa main${NC}             Checkout main in all repos"
echo -e "  ${YELLOW}gla -n 5${NC}              Show last 5 commits per repo"
echo ""
echo -e "${DIM}Run any command with --help for more options${NC}"
