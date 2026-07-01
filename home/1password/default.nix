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
let
   isLinux = pkgs.stdenv.isLinux;

   # npiperelay.exe — tiny Windows helper that relays a Windows named pipe to
   # stdio. Used on WSL to bridge the Windows 1Password SSH agent pipe into a
   # WSL unix socket via socat. Pinned prebuilt release (the tool is stable;
   # v0.1.0 is the only tagged release with published binaries).
   npiperelay = pkgs.fetchzip {
      url = "https://github.com/jstarks/npiperelay/releases/download/v0.1.0/npiperelay_windows_amd64.zip";
      hash = "sha256-GcwreB8BXYGNKJihE2xeelsroy+JFqLK1NK7Ycqxw5g=";
      stripRoot = false;
   };
in
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

      # WSL only: the npiperelay relay binary (see the zsh bootstrap below).
      home.file."./.local/bin/npiperelay.exe" = lib.mkIf isLinux {
         source = "${npiperelay}/npiperelay.exe";
         executable = true;
      };

      # socat is the WSL-side half of the SSH agent relay.
      home.packages = lib.optionals isLinux [ pkgs.socat ];

      programs.zsh.initContent = lib.mkMerge [
         # Source the op-load-secrets script to make the function available.
         # Order 500 ensures it loads before other init scripts.
         (lib.mkOrder 500 ''
           # Load op-load-secrets function from script
           if [[ -f "$HOME/.local/bin/op-load-secrets" ]]; then
             source "$HOME/.local/bin/op-load-secrets"
           fi
         '')

         # WSL ↔ Windows 1Password SSH agent bridge (Linux build only, and only
         # actually started under WSL). On WSL the 1Password keys live in the
         # Windows desktop app, which exposes its SSH agent as the named pipe
         # \\.\pipe\openssh-ssh-agent. socat + npiperelay.exe relay that pipe to
         # a unix socket at ~/.1password/agent.sock, which ssh/git consume via
         # IdentityAgent (see home/ssh/default.nix). On non-WSL Linux the app
         # provides that socket natively, so the relay is skipped.
         (lib.mkOrder 500 (lib.optionalString isLinux ''
           if grep -qi microsoft /proc/version 2>/dev/null; then
             export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
             if ! pgrep -f 'npiperelay.exe -ei -s //./pipe/openssh-ssh-agent' >/dev/null 2>&1; then
               [[ -S "$SSH_AUTH_SOCK" ]] && rm -f "$SSH_AUTH_SOCK"
               mkdir -p "$(dirname "$SSH_AUTH_SOCK")"
               (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork \
                 EXEC:"$HOME/.local/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
             fi
           fi
         ''))
      ];
   };
}
