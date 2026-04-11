#!/usr/bin/env bash
# Tmux lock screen with rolling PIN authentication.
# Runs cmatrix as screensaver. On keypress, shows lock screen.
# Unlocks when the last N characters typed match the PIN (no ENTER needed).
# Set PIN with: tmux-lock-set-pin.sh

# Tmux lock-command runs with minimal PATH; ensure Homebrew/Nix bins are reachable
export PATH="/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

PIN_FILE="$HOME/.config/tmux-lock-pin"

# No PIN file = no lock, just screensaver
if [[ ! -f "$PIN_FILE" ]]; then
    exec cmatrix -s
fi

# Read PIN file (format: line 1 = length, line 2 = hash)
PIN_LEN=$(sed -n '1p' "$PIN_FILE")
STORED_HASH=$(sed -n '2p' "$PIN_FILE")

# Detect old single-line format (hash only, no length)
if [[ -z "$STORED_HASH" ]]; then
    printf 'PIN file needs update. Run: tmux-lock-set-pin.sh\n'
    exec cmatrix -s
fi

show_lock_screen() {
    clear
    local cols lines top
    cols=$(tput cols 2>/dev/null || echo 80)
    lines=$(tput lines 2>/dev/null || echo 24)
    top=$(( (lines / 2) - 2 ))
    for ((i=0; i<top; i++)); do printf '\n'; done
    local pad
    for text in '░▒▓████████▓▒░' '░▒▓ LOCKED ▓▒░' '░▒▓████████▓▒░'; do
        pad=$(( (cols - ${#text}) / 2 ))
        printf '\033[0;32m%*s%s\033[0m\n' "$pad" '' "$text"
    done
}

while true; do
    cmatrix -s 2>/dev/null
    show_lock_screen

    buffer=""
    while true; do
        # Read one char silently; timeout returns to cmatrix
        if ! read -rsn1 -t 60 char; then
            break
        fi

        # Ignore non-printable characters (arrows, etc.)
        [[ -z "$char" ]] && continue

        buffer="${buffer}${char}"
        # Keep only the last PIN_LEN characters
        if (( ${#buffer} > PIN_LEN )); then
            buffer="${buffer: -$PIN_LEN}"
        fi

        # Check match once buffer is full
        if (( ${#buffer} == PIN_LEN )); then
            INPUT_HASH=$(printf '%s' "$buffer" | shasum -a 256 | cut -d' ' -f1)
            if [[ "$INPUT_HASH" = "$STORED_HASH" ]]; then
                clear
                exit 0
            fi
        fi
    done
done
