#!/usr/bin/env bash
# Tmux lock screen with rolling PIN authentication.
# Runs cmatrix as screensaver. On keypress, shows lock screen.
# Unlocks when the last N characters typed match the PIN (no ENTER needed).
# Set PIN with: tmux-lock-set-pin.sh

# Tmux lock-command runs with minimal PATH; ensure Homebrew/Nix bins are reachable
export PATH="/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

PIN_FILE="$HOME/.config/tmux-lock-pin"

# Screensaver: cmatrix only. Previous versions randomized over asciiquarium /
# pipes.sh / cbonsai / lavat / tty-clock, but the busy-loop animations
# (asciiquarium especially) pinned a full CPU core per pane. cmatrix uses sane
# ncurses refresh rates and stays well under 5% CPU.
SCREENSAVER="cmatrix -s"

# Reap screensaver children if this script dies before its normal exit path
# (e.g. tmux pane SIGHUP on disconnect). Without this, the foreground `eval`
# child below outlives its parent and becomes a 100%-CPU orphan adopted by
# PID 1. `pkill -P $$` kills only direct children of this script.
cleanup() { pkill -P $$ 2>/dev/null; tput cnorm 2>/dev/null; }
trap cleanup EXIT INT TERM HUP

run_screensaver() {
    eval "$SCREENSAVER" 2>/dev/null
}

# No PIN file = no lock, just screensaver
if [[ ! -f "$PIN_FILE" ]]; then
    eval "exec $SCREENSAVER"
fi

# Read PIN file (format: line 1 = length, line 2 = hash)
PIN_LEN=$(sed -n '1p' "$PIN_FILE")
STORED_HASH=$(sed -n '2p' "$PIN_FILE")

# Detect old single-line format (hash only, no length)
if [[ -z "$STORED_HASH" ]]; then
    printf 'PIN file needs update. Run: tmux-lock-set-pin.sh\n'
    exec cmatrix -s
fi

# Colors
BG=$'\033[1;32m'
DG=$'\033[38;5;22m'
R=$'\033[0m'

# Center a string on a given row
center() {
    local row=$1 text=$2
    local cols rows
    cols=$(tput cols)
    rows=$(tput lines)
    # Strip ANSI codes to measure visible width
    local plain
    plain=$(printf '%s' "$text" | sed $'s/\033\\[[0-9;]*m//g')
    local col=$(( (cols - ${#plain}) / 2 ))
    (( col < 0 )) && col=0
    tput cup "$row" "$col"
    printf '%s' "$text"
}

show_lock_screen() {
    local count=${1:-0}
    clear
    tput civis

    local cols rows mid
    cols=$(tput cols)
    rows=$(tput lines)
    mid=$(( rows / 2 ))

    # Build PIN dots: filled (*) and empty (.)
    local dots=""
    for ((i=0; i<PIN_LEN; i++)); do
        if (( i < count )); then
            dots="${dots} ${BG}*${DG}"
        else
            dots="${dots} ${DG}.${DG}"
        fi
    done
    dots="${dots# }"

    # Box width (inner 24 + 2 border = 26 visible chars)
    #   ┌────────────────────────┐
    #   │                        │
    #   │       LOCKED           │
    #   │                        │
    #   ├────────────────────────┤
    #   │        . . . .         │
    #   └────────────────────────┘
    local w=24

    center $(( mid - 4 )) "${DG}┌$(printf '%0.s─' $(seq 1 $w))┐${R}"
    center $(( mid - 3 )) "${DG}│$(printf '%*s' $w '')│${R}"
    center $(( mid - 2 )) "${DG}│${R}$(printf '%*s' $(( (w - 6) / 2 )) '')${BG}LOCKED${R}$(printf '%*s' $(( (w - 6 + 1) / 2 )) '')${DG}│${R}"
    center $(( mid - 1 )) "${DG}│$(printf '%*s' $w '')│${R}"
    center $(( mid + 0 )) "${DG}├$(printf '%0.s─' $(seq 1 $w))┤${R}"
    center $(( mid + 1 )) "${DG}│$(printf '%*s' $w '')│${R}"

    # PIN dots row - center the dots inside the box
    local dots_plain
    dots_plain=$(printf '%s' "$dots" | sed $'s/\033\\[[0-9;]*m//g')
    local dots_len=${#dots_plain}
    local lpad=$(( (w - dots_len) / 2 ))
    local rpad=$(( w - dots_len - lpad ))
    center $(( mid + 2 )) "${DG}│$(printf '%*s' $lpad '')${dots}$(printf '%*s' $rpad '')${DG}│${R}"

    center $(( mid + 3 )) "${DG}│$(printf '%*s' $w '')│${R}"
    center $(( mid + 4 )) "${DG}└$(printf '%0.s─' $(seq 1 $w))┘${R}"
    center $(( mid + 6 )) "${DG}enter pin to authenticate${R}"
}

while true; do
    run_screensaver
    show_lock_screen 0

    buffer=""
    display_count=0
    while true; do
        if ! read -rsn1 -t 60 char; then
            break
        fi

        [[ -z "$char" ]] && continue

        buffer="${buffer}${char}"
        display_count=$(( display_count + 1 ))

        if (( ${#buffer} > PIN_LEN )); then
            buffer="${buffer: -$PIN_LEN}"
            display_count=$PIN_LEN
        fi

        show_lock_screen "$display_count"

        if (( ${#buffer} == PIN_LEN )); then
            INPUT_HASH=$(printf '%s' "$buffer" | shasum -a 256 | cut -d' ' -f1)
            if [[ "$INPUT_HASH" = "$STORED_HASH" ]]; then
                clear
                tput cnorm
                exit 0
            fi
            # Mismatch: leave the rolling window intact. The trim above keeps
            # buffer at the last PIN_LEN chars, so the next keystroke just
            # shifts the window by one. Any PIN_LEN-length run anywhere in the
            # typed stream unlocks — no starting over from the first character.
        fi
    done
done
