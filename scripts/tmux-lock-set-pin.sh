#!/usr/bin/env bash
# Set or change the tmux lock screen PIN.
# Stores PIN length + SHA-256 hash. Never stores plaintext.
# Format: line 1 = length, line 2 = sha256 hash.

PIN_FILE="$HOME/.config/tmux-lock-pin"

# Read input one char at a time, printing * for each
read_secret() {
    local result=""
    local char
    while IFS= read -rsn1 char; do
        [[ -z "$char" ]] && break
        if [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
            if [[ -n "$result" ]]; then
                result="${result%?}"
                printf '\b \b'
            fi
            continue
        fi
        result="${result}${char}"
        printf '*'
    done
    printf '\n'
    eval "$1=\$result"
}

printf 'New PIN: '
read_secret pin

printf 'Confirm: '
read_secret pin2

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
