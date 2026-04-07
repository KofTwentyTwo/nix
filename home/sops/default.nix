# Sops Secrets Management
# =======================
# Decrypts secrets at activation time using age keys.
# Private key lives at ~/.config/sops/age/keys.txt (never in repo).
# Encrypted files live in secrets/ (safe to commit).
#
# To add a secret:
#   1. Encrypt: sops -e --age <pubkey> --input-type binary --output-type binary <file> > secrets/<name>.enc
#   2. Declare in sops.secrets below
#   3. Rebuild: darwin-rebuild switch --flake ~/.config/nix
#
# To edit a secret:
#   sops secrets/<name>.enc

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  config = {
    sops = {
      age.keyFile = "${homeDir}/.config/sops/age/keys.txt";

      secrets."aws-credentials" = {
        sopsFile = ../../secrets/aws-credentials.enc;
        format = "binary";
        path = "${homeDir}/.aws/credentials";
        mode = "0600";
      };
    };
  };
}
