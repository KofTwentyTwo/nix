# AWS Configuration Module
# ========================
# Manages AWS CLI configuration file (~/.aws/config).
# Credentials are managed by sops-nix (see home/sops/default.nix).
#
# Usage Options:
#   1. Declarative (default): Edit home/aws/config/config and rebuild
#   2. Interactive: Set enable = false, then use 'aws configure' command

{ config, pkgs, lib, ... }:

let
  enable = true;
in

{
  config = lib.mkIf enable {
    home.packages = with pkgs; [ awscli2 ];

    # AWS config (not sensitive, safe in Nix store)
    home.file.".aws/config" = {
      source = ./config/config;
    };

    # Credentials managed by sops-nix (home/sops/default.nix)
    # Decrypted from secrets/aws-credentials.enc -> ~/.aws/credentials (mode 0600)
  };
}
