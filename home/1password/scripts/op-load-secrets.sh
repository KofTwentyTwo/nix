#!/usr/bin/env bash
# Load environment variables from 1Password vault
# Usage: 
#   op-load-secrets                    # Load all API credentials from default vault
#   op-load-secrets --vault "MyVault" # Load from specific vault
#   op-load-secrets --account "my.1password.com" # Use specific account

# Don't use strict mode when sourced (zsh compatibility)
# When sourced, just define the function - strict mode can cause issues
set +euo pipefail

# Default vault for Nix secrets
DEFAULT_VAULT="NixEnvironmentVariables"
# Default account (Galaxy account)
DEFAULT_ACCOUNT="my.1password.com"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

op-load-secrets() {
  local vault="$DEFAULT_VAULT"
  local account="$DEFAULT_ACCOUNT"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --vault)
        vault="$2"
        shift 2
        ;;
      --account)
        account="$2"
        shift 2
        ;;
      --help|-h)
        cat <<EOF
Usage: op-load-secrets [OPTIONS]

Load environment variables from 1Password API Credential items.

This script loads all API Credential items from the specified vault.
Each item's title becomes an environment variable name (spaces → underscores, uppercase).
The credential field becomes the environment variable value.

Options:
  --vault VAULT     1Password vault name (default: $DEFAULT_VAULT)
  --account ACCOUNT 1Password account URL or email (default: $DEFAULT_ACCOUNT)
  --help, -h        Show this help

Examples:
  op-load-secrets                                    # Load from default vault/account
  op-load-secrets --vault "MyVault"                  # Load from specific vault
  op-load-secrets --account "other.1password.com"    # Use different account
  op-load-secrets --vault "Work" --account "work.com" # Specific vault and account
EOF
        return 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information" >&2
        return 1
        ;;
    esac
  done
  
  if ! command -v op >/dev/null 2>&1; then
    echo -e "${RED}⚠️  1Password CLI not found. Install it or ensure it's in PATH.${NC}" >&2
    return 1
  fi
  
  # Check if authenticated (silently)
  if ! op account list >/dev/null 2>&1; then
    echo -e "${RED}⚠️  1Password CLI not authenticated. Run: op signin${NC}" >&2
    return 1
  fi
  
  # Show cool banner
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║                                                          ║"
  echo "║     ${MAGENTA}🔐 SECURE ENVIRONMENT INITIALIZER 🔐${CYAN}${BOLD}                 ║"
  echo "║                                                          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}📦 Vault:${NC} ${BOLD}$vault${NC}"
  echo -e "${CYAN}👤 Account:${NC} ${BOLD}$account${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  # Get all items from vault in one call (optimized)
  echo -e "${YELLOW}[*]${NC} Accessing secure vault..."
  local vault_data=$(op --account "$account" item list --vault "$vault" --format json 2>/dev/null)
  
  if [[ -z "$vault_data" ]] || [[ "$vault_data" == "[]" ]]; then
    echo -e "${RED}✗${NC} No items found in vault: ${BOLD}$vault${NC} (account: $account)" >&2
    return 1
  fi
  
  # Count items and extract IDs in one pass
  local item_ids=($(echo "$vault_data" | jq -r '.[] | .id' 2>/dev/null))
  local item_count=${#item_ids[@]}
  
  if [[ $item_count -eq 0 ]]; then
    echo -e "${RED}✗${NC} No items found in vault: ${BOLD}$vault${NC} (account: $account)" >&2
    return 1
  fi
  
  echo -e "${GREEN}✓${NC} Found ${BOLD}$item_count${NC} item(s)"
  echo ""
  echo -e "${YELLOW}[*]${NC} Decrypting credentials..."
  
  local loaded=0
  local skipped=0
  
  # Process items (optimized: single jq call per item, but sequential for exports)
  for item_id in "${item_ids[@]}"; do
    # Get item details (single API call per item - can't be avoided)
    local item_json=$(op --account "$account" item get "$item_id" --format json 2>/dev/null)
    
    if [[ -z "$item_json" ]]; then
      continue
    fi
    
    # Extract all needed data in one jq call (faster)
    local item_data=$(echo "$item_json" | jq -r '
      if .category == "API_CREDENTIAL" then
        (.fields[]? | select(.id == "credential") | .value) as $cred |
        if $cred then
          "\(.title)|\($cred)"
        else
          empty
        end
      else
        empty
      end
    ' 2>/dev/null)
    
    if [[ -z "$item_data" ]]; then
      ((skipped++))
      continue
    fi
    
    IFS='|' read -r item_title credential <<< "$item_data"
    
    if [[ -z "$credential" ]]; then
      ((skipped++))
      continue
    fi
    
    # Convert title to environment variable name
    local env_name=$(echo "$item_title" | tr '[:lower:]' '[:upper:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
    
    # Export as environment variable
    export "$env_name=$credential"
    echo -e "  ${GREEN}✓${NC} ${CYAN}$env_name${NC} ${BLUE}→${NC} ${BOLD}${GREEN}LOADED${NC}"
    ((loaded++))
  done
  
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  if [[ $loaded -gt 0 ]]; then
    echo -e "${GREEN}${BOLD}✅ SUCCESS${NC} ${GREEN}Loaded $loaded secure environment variable(s)${NC}"
    if [[ $skipped -gt 0 ]]; then
      echo -e "${YELLOW}ℹ️  Skipped $skipped non-API-Credential item(s)${NC}" >&2
    fi
  else
    echo -e "${RED}${BOLD}✗ FAILED${NC} ${RED}No API Credential items found${NC}" >&2
    if [[ $skipped -gt 0 ]]; then
      echo -e "${YELLOW}   Found $skipped item(s) but none were API Credentials${NC}" >&2
    fi
    return 1
  fi
  
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# If script is executed directly (not sourced), run the function
# Safe check that works in both bash and zsh
if [[ -n "${BASH_VERSION:-}" ]] && [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  # Running as script in bash
  op-load-secrets "$@"
elif [[ -z "${ZSH_VERSION:-}" ]] && [[ "${0:-}" == *"op-load-secrets"* ]]; then
  # Running as script (not sourced) - fallback check
  op-load-secrets "$@"
fi
# When sourced, the function is just defined and available for use
