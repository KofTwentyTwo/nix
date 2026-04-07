# AWS Configuration Module
# ========================
# Manages AWS CLI configuration and credentials files (~/.aws/config and ~/.aws/credentials).
#
# This module:
#   - Creates the ~/.aws directory structure
#   - Manages AWS CLI configuration file
#   - Manages AWS CLI credentials file (encrypted with git-crypt)
#   - Provides standard AWS CLI settings
#
# Security:
#   - Credentials are stored in git using git-crypt encryption
#   - See .gitattributes for encryption rules
#   - Git hooks automatically unlock after git pull
#   - If needed, manually unlock: git-crypt unlock
#
# Usage Options:
#   1. Declarative (default): Edit home/aws/config/config and rebuild
#   2. Interactive: Set enable = false, then use 'aws configure' command
#
# IMPORTANT: If you use 'aws configure', it will overwrite this file.
#            Set enable = false below if you prefer to use 'aws configure'.
#
# Portability:
#   - Configuration is version controlled in this repo
#   - Works on any machine with AWS CLI installed
#   - Region and other settings can be customized per machine if needed

{ config, pkgs, lib, ... }:

let
  # Set to false if you want to use 'aws configure' instead of declarative management
  enable = true;
in

{
  config = lib.mkIf enable {
    # Install AWS CLI via Home Manager
    # This ensures the aws command is available in your PATH
    home.packages = with pkgs; [ awscli2 ];

    # Create AWS config directory and install config file
    # Home Manager will automatically create the .aws directory when this file is created
    home.file.".aws/config" = {
      source = ./config/config;
    };

    # Install AWS credentials directly (NOT via Nix store)
    # home.file copies into /nix/store which is world-readable (0444).
    # Instead, copy from the repo checkout and set restrictive permissions.
    home.activation.installAwsCredentials = lib.hm.dag.entryAfter ["writeBoundary"] ''
      src="${./config/credentials}"
      dst="$HOME/.aws/credentials"
      mkdir -p "$HOME/.aws"
      install -m 600 "$src" "$dst"
    '';
  };
}
