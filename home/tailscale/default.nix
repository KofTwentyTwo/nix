# Tailscale — Linux / standalone Home Manager (userspace, rootless)
# ================================================================
# macOS gets Tailscale from the `tailscale-app` cask + modules/tailscale.nix
# (nix-darwin, root activation). On Linux this repo is standalone Home Manager
# running as the UNPRIVILEGED user — there is no nix-darwin/NixOS and no
# `services.tailscale` (that's a NixOS-only module) — so we run `tailscaled` in
# USERSPACE-NETWORKING mode as a systemd *user* service. No root, no
# /dev/net/tun, no kernel module: it runs identically on WSL2, native Linux,
# or a container.
#
# The whole module is a no-op on Darwin (the cask owns that side); everything
# below sits under `lib.mkIf pkgs.stdenv.isLinux`.
#
# Capabilities (plain client):
#   + on the tailnet; reachable via Tailscale SSH (handled in-process, no proxy)
#   + reaches other nodes via the local SOCKS5 proxy on localhost:1055, e.g.
#       ALL_PROXY=socks5h://localhost:1055 curl http://othernode
#   - NOT an exit node / subnet router; no system DNS rewrite (accept-dns=false)
#     — those need the root system daemon (the "Full nodes" path not taken).
#
# Auth: a reusable auth key is decrypted from sops to
#   ~/.config/secrets/tailscale-authkey   (see home/sops/default.nix)
# and consumed by the tailscale-autoconnect oneshot. Until that secret exists
# the node simply runs logged-out (harmless); autoconnect logs and exits 0.
#
# Socket: a rootless daemon cannot use the default /var/run/tailscale socket, so
# it lives at $XDG_RUNTIME_DIR/tailscale/tailscaled.sock (systemd %t +
# RuntimeDirectory). The `tailscale` CLI defaults to the root socket, so the
# alias below pins it to the user socket — else `tailscale status` errors with
# "failed to connect".

{ config, pkgs, lib, ... }:

let
  # Relative to $XDG_RUNTIME_DIR (systemd %t for a --user service).
  sockRel = "tailscale/tailscaled.sock";

  # Oneshot login. systemd specifiers (%t) are NOT expanded inside a separate
  # script file, so we read $XDG_RUNTIME_DIR/$HOME from the user-service env.
  autoconnect = pkgs.writeShellScript "tailscale-autoconnect" ''
    set -u
    SOCK="$XDG_RUNTIME_DIR/${sockRel}"
    KEY="$HOME/.config/secrets/tailscale-authkey"
    TS="${pkgs.tailscale}/bin/tailscale --socket=$SOCK"

    # Wait for the daemon socket (tailscaled.service just started).
    for _ in $(seq 1 30); do [ -S "$SOCK" ] && break; sleep 1; done
    if [ ! -S "$SOCK" ]; then
      echo "[tailscale-autoconnect] daemon socket $SOCK absent; skipping"
      exit 0
    fi

    # Already authenticated? `tailscale status` exits 0 only when up.
    if $TS status >/dev/null 2>&1; then
      echo "[tailscale-autoconnect] already up; nothing to do"
      exit 0
    fi

    if [ ! -f "$KEY" ]; then
      echo "[tailscale-autoconnect] no auth key at $KEY yet; leaving node logged out"
      echo "[tailscale-autoconnect] mint a reusable key, sops-encrypt to secrets/tailscale-authkey.enc, git add, rebuild"
      exit 0
    fi

    echo "[tailscale-autoconnect] bringing node up (userspace, --ssh)"
    exec $TS up \
      --auth-key="file:$KEY" \
      --ssh \
      --accept-routes \
      --accept-dns=false
  '';
in
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = [ pkgs.tailscale ];

  # Interactive CLI -> the user (non-default) socket. `command` avoids alias
  # recursion; $XDG_RUNTIME_DIR is expanded by the shell at call time.
  programs.zsh.shellAliases.tailscale =
    "command tailscale --socket=$XDG_RUNTIME_DIR/${sockRel}";

  # Long-running node agent. %t = $XDG_RUNTIME_DIR, %S = state dir
  # (~/.local/state); RuntimeDirectory/StateDirectory create them with the
  # right ownership before ExecStart runs.
  systemd.user.services.tailscaled = {
    Unit.Description = "Tailscale node agent (userspace, rootless)";
    Service = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.tailscale}/bin/tailscaled"
        "--tun=userspace-networking"
        "--socket=%t/${sockRel}"
        "--statedir=%S/tailscale"
        "--socks5-server=localhost:1055"
        "--port=0"
      ];
      Restart = "on-failure";
      RestartSec = "5";
      RuntimeDirectory = "tailscale";
      StateDirectory = "tailscale";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Oneshot login: waits for the daemon, then `tailscale up` iff logged out and
  # a key is present. Idempotent and reboot-safe.
  systemd.user.services.tailscale-autoconnect = {
    Unit = {
      Description = "Authenticate & bring up Tailscale (userspace)";
      After = [ "tailscaled.service" ];
      Wants = [ "tailscaled.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${autoconnect}";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
