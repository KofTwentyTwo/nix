#!/usr/bin/env bash
# Check for tmux lock PIN and prompt to set one if missing.
# Called from tmux session-created hook.

# Tmux hooks run with minimal PATH; ensure Homebrew/Nix bins are reachable
export PATH="/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

PIN_FILE="$HOME/.config/tmux-lock-pin"

[[ -f "$PIN_FILE" ]] && exit 0

# Let the session fully initialize before showing popup
sleep 1

tmux display-popup -E -w 52 -h 10 -T " Lock PIN Required " \
    bash -c 'printf "Sessions lock after 15 minutes idle.\nSet a PIN to secure the lock screen.\n\n"; exec "$HOME/.local/bin/tmux-lock-set-pin.sh"'
