#!/usr/bin/env bash
# Rename a tmux session, with duplicate name detection.
# Called from tmux-session-name.sh via command-prompt callback.
# Usage: tmux-session-rename.sh <session-id> <new-name>

session_id="$1"
new_name="$2"

# Empty name means user pressed Enter to skip
[ -z "$new_name" ] && exit 0

# Check if a session with this name already exists (= prefix = exact match)
if tmux has-session -t "=${new_name}" 2>/dev/null; then
  tmux display-message "Session '${new_name}' already exists"
  exit 0
fi

tmux rename-session -t "$session_id" -- "$new_name"
