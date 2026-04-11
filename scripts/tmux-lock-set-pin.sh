#!/usr/bin/env bash
# Set or change the tmux lock screen PIN.
# Stores PIN length + SHA-256 hash. Never stores plaintext.
# Format: line 1 = length, line 2 = sha256 hash.

PIN_FILE="$HOME/.config/tmux-lock-pin"

printf 'New PIN: '
read -rs pin
printf '\n'

printf 'Confirm: '
read -rs pin2
printf '\n'

if [[ -z "$pin" ]]; then
    printf 'PIN cannot be empty.\n'
    exit 1
fi

if [[ "$pin" != "$pin2" ]]; then
    printf 'PINs do not match.\n'
    exit 1
fi

mkdir -p "$(dirname "$PIN_FILE")"
HASH=$(printf '%s' "$pin" | shasum -a 256 | cut -d' ' -f1)
printf '%d\n%s\n' "${#pin}" "$HASH" > "$PIN_FILE"
chmod 600 "$PIN_FILE"
printf 'PIN set (%d characters).\n' "${#pin}"
