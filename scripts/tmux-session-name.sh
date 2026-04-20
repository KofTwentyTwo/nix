#!/usr/bin/env bash
# Prompt to name new tmux sessions that have default numeric names.
# Called from tmux session-created hook. Press Enter to skip.

export PATH="/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

# Let the session render before prompting
sleep 0.3

session=$(tmux display-message -p '#{session_name}')

# Only prompt if session has a default numeric name (0, 1, 2, ...)
if [[ "$session" =~ ^[0-9]+$ ]]; then
  tmux command-prompt -p "Name this session (Enter to skip):" \
    "if-shell -F '%1' 'rename-session -- \"%1\"'"
fi
