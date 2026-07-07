# AWS Configuration Module
# ========================
# Manages AWS CLI configuration file (~/.aws/config).
# Credentials are managed by sops-nix (see home/sops/default.nix).
#
# Usage Options:
#   1. Declarative (default): Edit home/aws/config/config and rebuild
#   2. Interactive: Set enable = false, then use 'aws configure' command

{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [ awscli2 ];

  # AWS config (not sensitive, safe in Nix store)
  home.file.".aws/config" = {
    source = ./config/config;
  };

  # Credentials managed by sops-nix (home/sops/default.nix)
  # Decrypted from secrets/aws-credentials.enc -> ~/.aws/credentials (mode 0600)
  # NB: home/aws/config/credentials in the repo is a comment-only stub — the
  # real auth model is SSO (sso-sessions in the config above); short-lived
  # tokens land in the machine-local ~/.aws/sso/ cache via `aws sso login`.

  # LORE bridge: mirror the same SSO config into Windows-native %USERPROFILE%\.aws
  # so the Windows aws CLI (scoop) sees the identical profiles. SSO token
  # caches stay per-side (each side runs its own `aws sso login`).
  home.activation.syncWindowsAwsConfig = lib.mkIf pkgs.stdenv.isLinux (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    win="/mnt/c/Users/james/.aws"
    if [ -d "/mnt/c/Users/james" ]; then
      mkdir -p "$win"
      # --no-preserve=mode: plain cp keeps the store's 0444, which drvfs maps
      # to the Windows READ-ONLY attribute and breaks `aws configure` writes.
      if cp -f --no-preserve=mode,ownership ${./config/config} "$win/config" 2>/dev/null; then
        echo "[aws-win] config mirrored to Windows .aws"
      else
        echo "[aws-win] WARN: could not mirror config to $win" >&2
      fi
    fi
  '');
}
