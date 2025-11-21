# 1Password Integration Module
# ============================
# Configures 1Password integration for:
#   - SSH agent (see ssh/default.nix)
#   - Environment variable loading from 1Password vaults
#
# Features:
#   - 1Password SSH agent configuration
#   - op-load-secrets script for loading secrets as environment variables
#
# Usage:
#   - Use the "secure" alias to load secrets from "NixEnvironmentVariables" vault
#   - Run `op-load-secrets --help` for manual usage
#   - See SECRETS.md for detailed documentation
#
# Portability:
#   - Works on any Mac with 1Password CLI installed
#   - Default vault can be changed in scripts/op-load-secrets.sh

{ config, pkgs, lib, ... }:
{
   config = {
      # 1Password SSH agent configuration
      # This enables 1Password to manage SSH keys
      home.file."./.config/1password/agent.toml" = {
         source = ./config/agent.toml;
      };

      # Install op-load-secrets script
      # This script loads environment variables from 1Password API Credential items
      home.file."./.local/bin/op-load-secrets" = {
         source = ./scripts/op-load-secrets.sh;
         executable = true;
      };

      # Source the script in zsh to make the function available
      # Order 500 ensures it loads before other init scripts
      programs.zsh.initContent = lib.mkOrder 500 ''
        # Load op-load-secrets function from script
        if [[ -f "$HOME/.local/bin/op-load-secrets" ]]; then
          source "$HOME/.local/bin/op-load-secrets"
        fi
      '';
   };
}
