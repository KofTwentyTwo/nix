#!/usr/bin/env bash
# claude-resume.sh - Resume the most recent Claude session for current directory
#
# Usage: claude-resume.sh
#        cr  (alias)
#
# Finds the most recent Claude Code session for the current working directory
# and resumes it. This is directory-scoped, unlike `claude --continue` which
# resumes the globally most recent session.

set -euo pipefail

# Convert current directory to Claude's project folder naming scheme
# /Users/james.maes/.config/nix -> -Users-james-maes--config-nix
project_path=$(pwd | sed 's|/|-|g' | sed 's|^-||')
sessions_dir="${HOME}/.claude/projects/${project_path}"

if [[ ! -d "$sessions_dir" ]]; then
    echo "No Claude sessions found for this directory."
    echo "Starting fresh session..."
    exec claude
fi

# Find the most recent session file (exclude agent-* files, get UUID sessions only)
latest_session=$(ls -t "$sessions_dir"/*.jsonl 2>/dev/null | grep -v 'agent-' | head -1 || true)

if [[ -z "$latest_session" ]]; then
    echo "No sessions found in $sessions_dir"
    echo "Starting fresh session..."
    exec claude
fi

# Extract session ID from filename (e.g., "1add549c-4454-48d9-a2cd-0087d5e3607a.jsonl" -> "1add549c-4454-48d9-a2cd-0087d5e3607a")
session_id=$(basename "$latest_session" .jsonl)

echo "Resuming session: $session_id"
exec claude --resume "$session_id"
