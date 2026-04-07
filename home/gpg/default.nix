# GPG Configuration
# =================
# Declarative GPG and gpg-agent setup via Home Manager modules.
# Uses pinentry-mac for GUI passphrase prompts on macOS.
# Agent managed via launchd (automatic start/restart).

{ config, pkgs, lib, ... }:

{
  config = {
    programs.gpg = {
      enable = true;
    };

    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 28800;     # 8 hours
      maxCacheTtl = 28800;         # 8 hours
      pinentry.package = pkgs.pinentry_mac;
    };
  };
}
