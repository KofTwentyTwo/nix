#!/usr/bin/env bash
# Set or change the tmux lock screen PIN.
# Stores SHA-256 hash only, never plaintext.

PIN_FILE="$HOME/.config/tmux-lock-pin"

printf 'New PIN: '
read -rs pin
printf '\n'

printf 'Confirm: '
read -rs pin2
printf '\n'

if [[ "$pin" != "$pin2" ]]; then
    printf 'PINs do not match.\n'
    exit 1
fi

if [[ -z "$pin" ]]; then
    printf 'PIN cannot be empty.\n'
    exit 1
fi

mkdir -p "$(dirname "$PIN_FILE")"
printf '%s' "$pin" | shasum -a 256 | cut -d' ' -f1 > "$PIN_FILE"
chmod 600 "$PIN_FILE"
printf 'PIN set.\n'
