# Python Package Management
# =========================
# Declarative management of pipx applications and pip3 libraries.
# Ensures consistent Python tooling across machines.
#
# pipx and pip3 are installed via Homebrew.
# This module runs install commands on every `darwin-rebuild switch`.

{ config, pkgs, lib, ... }:

{
  home.activation.pythonPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/opt/homebrew/bin:$PATH"

    # pipx applications (isolated CLI tools)
    if command -v pipx &>/dev/null; then
      pipx install ansible-builder 2>/dev/null || true
      pipx install ansible-navigator 2>/dev/null || true
    fi

    # pip3 libraries (system-level)
    if command -v pip3 &>/dev/null; then
      pip3 install --quiet --break-system-packages \
        cryptography \
        linkify-it-py \
        notmuch2 \
        pillow \
        requests \
        textual \
        2>/dev/null || true
    fi
  '';
}
