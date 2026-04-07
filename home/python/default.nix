# Python Package Management
# =========================
# Declarative management of Python libraries (via Nix) and pipx applications.
# Ensures consistent Python tooling across machines.
#
# Libraries are installed as Nix packages (no --break-system-packages needed).
# pipx applications are installed via activation script (Homebrew pipx).

{ config, pkgs, lib, ... }:

{
  # Python libraries via Nix (replaces pip3 --break-system-packages)
  home.packages = with pkgs.python3Packages; [
    cryptography
    linkify-it-py
    notmuch2
    pillow
    requests
    textual
  ];

  # pipx applications (isolated CLI tools, via Homebrew pipx)
  home.activation.pythonPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/opt/homebrew/bin:$PATH"

    if command -v pipx &>/dev/null; then
      pipx install ansible-builder 2>/dev/null || true
      pipx install ansible-navigator 2>/dev/null || true
    fi
  '';
}
