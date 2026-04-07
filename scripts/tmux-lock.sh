#!/usr/bin/env bash
# Tmux lock screen with PIN authentication.
# Runs cmatrix, prompts for PIN to unlock. Wrong PIN re-locks.
# Set PIN with: tmux-lock-set-pin.sh

# Tmux lock-command runs with minimal PATH; ensure Homebrew/Nix bins are reachable
export PATH="/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

PIN_FILE="$HOME/.config/tmux-lock-pin"

# No PIN file = no lock, just screensaver
if [[ ! -f "$PIN_FILE" ]]; then
    exec cmatrix -s
fi

STORED_HASH=$(<"$PIN_FILE")

while true; do
    cmatrix -s 2>/dev/null

    # Styled inline PIN prompt, centered on screen
    clear
    COLS=$(tput cols 2>/dev/null || echo 80)
    LINES=$(tput lines 2>/dev/null || echo 24)

    # Vertical centering: move cursor to middle of screen
    TOP=$(( (LINES / 2) - 3 ))
    for ((i=0; i<TOP; i++)); do printf '\n'; done

    # Horizontal centering helper
    center() { local pad=$(( (COLS - ${#1}) / 2 )); printf '%*s%s\n' "$pad" '' "$1"; }

    printf '\033[0;32m'
    center '░▒▓████████▓▒░'
    center '░▒▓ LOCKED ▓▒░'
    center '░▒▓████████▓▒░'
    printf '\n'
    # PIN prompt: center the "PIN: " label, then read inline
    local_pad=$(( (COLS - 10) / 2 ))
    printf '%*s%s' "$local_pad" '' 'PIN: '
    read -rs pin
    printf '\n'

    INPUT_HASH=$(printf '%s' "$pin" | shasum -a 256 | cut -d' ' -f1)
    if [[ "$INPUT_HASH" = "$STORED_HASH" ]]; then
        clear
        printf '\033[0m'
        exit 0
    fi

    printf '\033[31m'
    center 'ACCESS DENIED'
    printf '\033[0m'
    sleep 1
done
