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
  # Skip install when the venv already exists so activation stays quiet.
  home.activation.pythonPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/opt/homebrew/bin:$PATH"

    if command -v pipx &>/dev/null; then
      for pkg in ansible-builder ansible-navigator; do
        if [ ! -d "$HOME/.local/pipx/venvs/$pkg" ]; then
          pipx install "$pkg"
        fi
      done
    fi
  '';
}
