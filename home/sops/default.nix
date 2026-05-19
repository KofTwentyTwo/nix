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

      # DISABLED 2026-05-19: aws-credentials.enc is encrypted only to the
      # "darth" age key; this machine (Dark-Horse) cannot decrypt it, so
      # sops-install-secrets (fail-fast) aborts the whole batch and blocks
      # every other secret. To restore: on a machine with the darth key,
      # decrypt aws-credentials.enc, then re-encrypt with both recipients
      # (`sops updatekeys secrets/aws-credentials.enc`), commit, and
      # uncomment this block.
      # secrets."aws-credentials" = {
      #   sopsFile = ../../secrets/aws-credentials.enc;
      #   format = "binary";
      #   path = "${homeDir}/.aws/credentials";
      #   mode = "0600";
      # };

      # GitHub fine-grained PAT for org-wide security alert reads
      # (Dependabot, code scanning, secret scanning) across greater-goods,
      # gg-engineering, gg-devops, gg-sandboxes. Consumed by the morning
      # security digest. Rotate when the GitHub token expires.
      secrets."github-security-pat" = {
        sopsFile = ../../secrets/github-security-pat.enc;
        format = "binary";
        path = "${homeDir}/.github-security-pat";
        mode = "0600";
      };
    };
  };
}
