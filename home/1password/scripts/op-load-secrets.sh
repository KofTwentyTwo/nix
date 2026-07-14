#!/usr/bin/env bash
# Load environment variables from 1Password vault
# Usage:
#   op-load-secrets                    # Load all API credentials from default vault
#   op-load-secrets --vault "MyVault" # Load from specific vault
#   op-load-secrets --account "my.1password.com" # Use specific account
#   op-load-secrets --verbose          # Banner + per-item output
#
# Output is one summary line by default; pass --verbose for the full ceremony.
#
# The vault itself contains an OP_SERVICE_ACCOUNT_TOKEN item. Once exported,
# a bare `op` would silently authenticate as that (k8s-galaxy-scoped) service
# account instead of the desktop-app session, and every later call here would
# fail. Two defenses: all op calls run with the hijacking vars unset, and
# exports are deferred until the fetch loop has finished.

# Default vault for Nix secrets
DEFAULT_VAULT="NixEnvironmentVariables"
# Default account (Galaxy account)
DEFAULT_ACCOUNT="my.1password.com"

op-load-secrets() {
  local vault="$DEFAULT_VAULT"
  local account="$DEFAULT_ACCOUNT"
  local verbose=0

  # Colors ($'..' works in bash and zsh; plain echo renders them in both)
  local RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m'
  local CYAN=$'\033[0;36m' BLUE=$'\033[0;34m' MAGENTA=$'\033[0;35m'
  local BOLD=$'\033[1m' NC=$'\033[0m'

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
      --verbose|-v)
        verbose=1
        shift
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
  --verbose, -v     Banner and per-item output (default: one summary line)
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

  # Every op call goes through this wrapper: unset the env vars that would
  # override the desktop-app session (a previous run of this very function
  # exports OP_SERVICE_ACCOUNT_TOKEN from the vault). --account pins the
  # personal account regardless of OP_ACCOUNT.
  _op() {
    env -u OP_SERVICE_ACCOUNT_TOKEN -u OP_CONNECT_HOST -u OP_CONNECT_TOKEN \
      op --account "$account" "$@"
  }

  if ! command -v op >/dev/null 2>&1; then
    echo "${RED}secure: 1Password CLI not found. Install it or ensure it's in PATH.${NC}" >&2
    return 1
  fi

  if [[ $verbose -eq 1 ]]; then
    echo "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║     ${MAGENTA}🔐 SECURE ENVIRONMENT INITIALIZER 🔐${CYAN}${BOLD}                 ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo "${NC}"
    echo "${CYAN}📦 Vault:${NC} ${BOLD}$vault${NC}   ${CYAN}👤 Account:${NC} ${BOLD}$account${NC}"
    echo ""
  fi

  # Single list call; on failure show op's own error (auth timeout, unknown
  # vault, locked app, ...) instead of a generic "no items".
  local vault_data
  if ! vault_data=$(_op item list --vault "$vault" --format json 2>&1); then
    echo "${RED}secure: ✗ cannot read vault ${BOLD}$vault${NC}${RED} ($account):${NC} $vault_data" >&2
    return 1
  fi

  # id<TAB>title pairs, in list order
  local -a item_ids item_titles
  local id title
  while IFS=$'\t' read -r id title; do
    [[ -n "$id" ]] || continue
    item_ids+=("$id")
    item_titles+=("$title")
  done < <(printf '%s\n' "$vault_data" | jq -r '.[] | "\(.id)\t\(.title)"' 2>/dev/null)

  if [[ ${#item_ids[@]} -eq 0 ]]; then
    echo "${RED}secure: ✗ no items found in vault ${BOLD}$vault${NC}${RED} (account: $account)${NC}" >&2
    return 1
  fi

  # Fetch phase — nothing is exported yet, so a mid-loop export can never
  # change how the remaining calls authenticate.
  local -a export_pairs failed_titles skipped_titles
  local i=0 item_json env_name credential
  for id in "${item_ids[@]}"; do
    title="${item_titles[@]:$i:1}"
    i=$((i + 1))

    item_json=$(_op item get "$id" --format json 2>/dev/null)
    if [[ -z "$item_json" ]]; then
      failed_titles+=("$title")
      continue
    fi

    if [[ "$(printf '%s\n' "$item_json" | jq -r '.category' 2>/dev/null)" != "API_CREDENTIAL" ]]; then
      skipped_titles+=("$title")
      continue
    fi

    credential=$(printf '%s\n' "$item_json" \
      | jq -r '.fields[]? | select(.id == "credential") | .value // empty' 2>/dev/null)
    if [[ -z "$credential" ]]; then
      failed_titles+=("$title")
      continue
    fi

    env_name=$(printf '%s\n' "$title" | tr '[:lower:]' '[:upper:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
    export_pairs+=("$env_name=$credential")
    [[ $verbose -eq 1 ]] && echo "  ${GREEN}✓${NC} ${CYAN}$env_name${NC}"
  done

  # Export phase — only after every fetch has completed.
  local pair loaded=0 sa_note=0
  for pair in "${export_pairs[@]}"; do
    export "$pair"
    loaded=$((loaded + 1))
    [[ "${pair%%=*}" == "OP_SERVICE_ACCOUNT_TOKEN" ]] && sa_note=1
  done

  # Summary
  local summary="🔐 secure: loaded ${GREEN}${BOLD}$loaded${NC}/${#item_ids[@]} vars from $vault"
  [[ ${#skipped_titles[@]} -gt 0 ]] && summary+=" ${YELLOW}(${#skipped_titles[@]} non-credential skipped)${NC}"
  echo "$summary"

  if [[ ${#failed_titles[@]} -gt 0 ]]; then
    echo "${RED}   ✗ failed:${NC} ${failed_titles[*]}" >&2
  fi
  if [[ $sa_note -eq 1 ]]; then
    echo "${YELLOW}   ℹ OP_SERVICE_ACCOUNT_TOKEN exported — bare \`op\` in this shell now uses the service account (secure itself is unaffected)${NC}"
  fi

  [[ $loaded -gt 0 ]] || return 1
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
