# Tailscale Preference Management (nix-darwin)
# ============================================
# nix-darwin has no first-class `services.tailscale` module (that's NixOS-only).
# The Tailscale macOS GUI app — installed as the `tailscale-app` cask in
# modules/homebrew.nix — holds its persistent preferences in `ipn-state`
# files outside Nix's awareness.
#
# This module bridges the gap by emitting a single idempotent activation
# script that calls `tailscale set` with the per-machine flags declared in
# flake.nix's `machineConfigs`. `tailscale set` is a no-op when the desired
# state already matches, so it's safe to run on every `darwin-rebuild switch`.
#
# Caveat: if you toggle a Tailscale pref via the macOS menu-bar app (e.g.
# turn off "Use Tailscale DNS"), the next `darwin-rebuild switch` will revert
# it to whatever this module declares. That's the trade-off of declarative
# override of stateful settings — desired 95% of the time.
#
# Approvals (subnet routes, exit node) still happen in the admin console at
# https://login.tailscale.com/admin/machines — Tailscale exposes no CLI for
# admin-side approval, so that step remains manual per host.

{ pkgs, lib, machineConfig ? {}, ... }:

let
  ts = machineConfig.tailscale or {};

  advertiseRoutes   = ts.advertiseRoutes or [];
  acceptDns         = ts.acceptDns or true;
  acceptRoutes      = ts.acceptRoutes or true;
  advertiseExitNode = ts.advertiseExitNode or false;

  # `--advertise-routes=` with an empty value clears all advertised routes.
  routesArg =
    if advertiseRoutes == []
    then "--advertise-routes="
    else "--advertise-routes=${lib.concatStringsSep "," advertiseRoutes}";

  # The Tailscale GUI app installs its CLI symlink at /usr/local/bin/tailscale
  # on both Intel and Apple Silicon (it is the app's own install, not a brew
  # formula at /opt/homebrew/bin).
  tailscaleBin = "/usr/local/bin/tailscale";
in
{
   ###########################################################################
   ## Activation: sync Tailscale prefs to the declared per-machine state.   ##
   ## Runs on every `darwin-rebuild switch`; idempotent.                    ##
   ###########################################################################
   system.activationScripts.tailscalePrefs.text = ''
      if [ ! -x "${tailscaleBin}" ]; then
         echo "[tailscale] CLI not found at ${tailscaleBin} — skipping prefs sync"
      elif ! /usr/bin/pgrep -qif "Tailscale|tailscaled"; then
         echo "[tailscale] daemon not running — skipping prefs sync (will sync on next rebuild)"
      else
         echo "[tailscale] syncing prefs (routes=${toString advertiseRoutes} exitNode=${lib.boolToString advertiseExitNode} acceptDns=${lib.boolToString acceptDns} acceptRoutes=${lib.boolToString acceptRoutes})"
         ${tailscaleBin} set \
            ${routesArg} \
            --accept-dns=${lib.boolToString acceptDns} \
            --accept-routes=${lib.boolToString acceptRoutes} \
            --advertise-exit-node=${lib.boolToString advertiseExitNode} \
            || echo "[tailscale] warning: 'tailscale set' failed; check 'tailscale status'"
      fi
   '';
}
