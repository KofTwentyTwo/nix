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
      # pinentry-mac is darwin-only; on Linux (WSL, typically headless) fall
      # back to the curses/tty pinentry so the agent still builds and prompts.
      pinentry.package =
        if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
    };
  };
}
