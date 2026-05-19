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

      # GitHub fine-grained PAT for org-wide security alert reads:
      # see home.activation.deployGithubSecurityPat below. We bypass
      # sops-nix's symlink-based deployment because the consumer is a
      # Claude Cowork sandboxed scheduled task that only mounts the
      # project folder and ~/Git.Local/dmd — a symlink pointing into
      # ~/.config/sops-nix/ dangles from inside the sandbox.
    };

    # Deploy the GitHub security PAT as a REGULAR FILE (not a sops-nix
    # symlink) directly inside the Claude Cowork project folder so the
    # sandboxed morning digest can read it. Runs after writeBoundary so
    # home.file deployments have settled. Decryption uses the same
    # secrets/github-security-pat.enc + ~/.config/sops/age/keys.txt the
    # sops-nix agent would use, so the encryption story, recipient list,
    # and `sops updatekeys` workflow are unchanged.
    #
    # Gracefully skips on hosts without an age key or without the Cowork
    # project folder — Grogu / Renova / Darth get a no-op.
    home.activation.deployGithubSecurityPat = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      PROJECT_DIR="${homeDir}/Documents/Claude/Projects/Security Alerts"
      DST="$PROJECT_DIR/.github-pat"
      ENC="${../../secrets/github-security-pat.enc}"
      AGE_KEY="${homeDir}/.config/sops/age/keys.txt"

      # Transitional cleanup: remove orphaned plaintext from the previous
      # sops-nix-managed deployment pattern. Guarded by -L / -f so we only
      # touch files that match the legacy layout exactly. Safe to keep
      # permanently — idempotent and no-op once cleaned.
      if [ -L "${homeDir}/.github-security-pat" ]; then
        rm "${homeDir}/.github-security-pat"
        echo "[github-pat] removed legacy symlink at ~/.github-security-pat"
      fi
      if [ -f "${homeDir}/.config/sops-nix/secrets/github-security-pat" ]; then
        rm "${homeDir}/.config/sops-nix/secrets/github-security-pat"
        echo "[github-pat] removed orphan plaintext at ~/.config/sops-nix/secrets/github-security-pat"
      fi

      if [ ! -f "$AGE_KEY" ]; then
        echo "[github-pat] no age key at $AGE_KEY; skipping deployment"
        exit 0
      fi

      if [ ! -d "$PROJECT_DIR" ]; then
        echo "[github-pat] no project dir at $PROJECT_DIR; skipping deployment"
        exit 0
      fi

      # mktemp in the destination directory so the final mv is an atomic
      # rename on the same filesystem (mktemp's default 0600 perms are
      # preserved through the redirect because > truncates without
      # touching mode bits).
      TMP="$(mktemp "$PROJECT_DIR/.github-pat.XXXXXX")"
      if SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops --decrypt \
           --input-type binary --output-type binary "$ENC" > "$TMP"; then
        mv "$TMP" "$DST"
        echo "[github-pat] deployed to $DST (mode 0600)"
      else
        rm -f "$TMP"
        echo "[github-pat] sops decryption failed; $DST not updated" >&2
      fi
    '';
  };
}
