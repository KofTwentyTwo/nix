#!/usr/bin/env bash
# git-pane-info.sh - Asynchronously fetches Git repository name and branch for tmux border status.
# Prevents input lag on large or slow repositories.

set -euo pipefail

# Argument: path to check
PANE_PATH="${1:-}"

# Fallback output
DEFAULT_OUTPUT="#[fg=#444444][#[fg=#888888]n/a#[fg=#444444]] [#[fg=#888888]n/a#[fg=#444444]]"

if [[ -z "$PANE_PATH" || ! -d "$PANE_PATH" ]]; then
  echo "$DEFAULT_OUTPUT"
  exit 0
fi

# Ensure cache directory exists
CACHE_DIR="/tmp/git-cache-$(id -u)"
mkdir -p "$CACHE_DIR"

# Compute hash of the path to keep cache filenames safe and unique
# md5 is standard on macOS; md5sum on Linux
if command -v md5sum >/dev/null 2>&1; then
  HASH=$(printf "%s" "$PANE_PATH" | md5sum | cut -d' ' -f1)
else
  HASH=$(printf "%s" "$PANE_PATH" | md5)
fi

CACHE_FILE="$CACHE_DIR/$HASH"
LOCK_DIR="$CACHE_FILE.lock"

# Function to query Git synchronously
get_git_info() {
  local target_path="$1"
  if ! cd "$target_path" 2>/dev/null; then
    echo "$DEFAULT_OUTPUT"
    return
  fi

  local toplevel
  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$toplevel" ]]; then
    echo "$DEFAULT_OUTPUT"
    return
  fi

  local repo_name
  repo_name=$(basename "$toplevel")

  local branch_name
  branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "n/a")

  echo "#[fg=#444444][#[fg=#888888]${repo_name}#[fg=#444444]] [#[fg=#888888]${branch_name}#[fg=#444444]]"
}

# Function to spawn background updater
trigger_update_bg() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    (
      trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
      local tmp_file="$CACHE_FILE.tmp"
      get_git_info "$PANE_PATH" > "$tmp_file"
      mv "$tmp_file" "$CACHE_FILE"
    ) & disown
  fi
}

# Check if cache exists
if [[ -f "$CACHE_FILE" ]]; then
  # Print cached value immediately
  cat "$CACHE_FILE"
  
  # Check age
  mod_time=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null || stat -c "%Y" "$CACHE_FILE" 2>/dev/null || echo "0")
  now=$(date +%s)
  age=$((now - mod_time))
  
  # If cache is older than 5 seconds, trigger background update
  if [[ "$age" -gt 5 ]]; then
    trigger_update_bg
  fi
else
  # No cache yet, print default and trigger update
  echo "$DEFAULT_OUTPUT"
  trigger_update_bg
fi
