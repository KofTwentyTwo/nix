# Sops Secrets Management
# =======================
# Decrypts secrets at activation time using age keys.
# Private key lives at ~/.config/sops/age/keys.txt (never in repo).
# Encrypted files live in secrets/ (safe to commit).
#
# To add a secret:
#   1. Encrypt: sops -e --filename-override secrets/<name>.enc \
#        --input-type binary --output-type binary <file> > secrets/<name>.enc
#      (relies on .sops.yaml creation_rules to pick recipients by filename)
#   2. Either declare in sops.secrets (default sops-nix symlink layout), or
#      pass to mkPatDeployer (regular-file layout for sandboxed consumers).
#   3. Rebuild: darwin-rebuild switch --flake ~/.config/nix
#
# To edit a secret:
#   sops secrets/<name>.enc

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;
  ageKey = "${homeDir}/.config/sops/age/keys.txt";

  # Decrypt a sops-encrypted secret directly to one or more regular files,
  # bypassing sops-nix's default symlink-into-~/.config/sops-nix/ layout.
  # Use when the consumer is sandboxed (e.g. a Claude Cowork scheduled task)
  # and only mounts specific paths — symlinks pointing outside those mounts
  # dangle from inside the sandbox.
  #
  # Per-destination behavior:
  #   - skips if the parent dir doesn't exist (project not yet set up)
  #   - mktemp in the destination dir so the final mv is atomic on the same
  #     filesystem (mktemp's 0600 default mode is preserved through `>`)
  #
  # Whole-deployer behavior: no-op if the age key is missing (host without
  # sops set up yet).
  mkPatDeployer = { name, encFile, destinations }:
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ENC="${encFile}"
      AGE_KEY="${ageKey}"

      if [ ! -f "$AGE_KEY" ]; then
        echo "[${name}] no age key at $AGE_KEY; skipping deployment"
        exit 0
      fi

      deploy_one() {
        dst="$1"
        dst_dir="$(dirname "$dst")"

        if [ ! -d "$dst_dir" ]; then
          echo "[${name}] $dst_dir missing; skipping $dst"
          return 0
        fi

        tmp="$(mktemp "$dst_dir/.pat.XXXXXX")"
        if SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops --decrypt \
             --input-type binary --output-type binary "$ENC" > "$tmp"; then
          mv "$tmp" "$dst"
          echo "[${name}] deployed to $dst (mode 0600)"
        else
          rm -f "$tmp"
          echo "[${name}] sops decryption failed; $dst not updated" >&2
        fi
      }

      ${lib.concatMapStringsSep "\n      "
          (d: "deploy_one ${lib.escapeShellArg d}")
          destinations}
    '';
in
{
  config = {
    sops = {
      age.keyFile = ageKey;

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

      # GitHub fine-grained PATs are deployed via the home.activation entries
      # below (see mkPatDeployer in `let`). We bypass sops-nix's symlink
      # layout because the consumers are Claude Cowork sandboxed scheduled
      # tasks that only mount their project folders.
    };

    # Transitional cleanup: remove orphaned artifacts from the previous
    # sops-nix-managed deployment of github-security-pat. Idempotent —
    # the -L / -f guards make it a no-op on hosts where the legacy layout
    # never existed (Grogu, Renova, future hosts). Safe to keep permanently.
    home.activation.cleanupLegacyGithubSecurityPat =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -L "${homeDir}/.github-security-pat" ]; then
          rm "${homeDir}/.github-security-pat"
          echo "[github-security-pat-cleanup] removed legacy symlink at ~/.github-security-pat"
        fi
        if [ -f "${homeDir}/.config/sops-nix/secrets/github-security-pat" ]; then
          rm "${homeDir}/.config/sops-nix/secrets/github-security-pat"
          echo "[github-security-pat-cleanup] removed orphan plaintext at ~/.config/sops-nix/secrets/github-security-pat"
        fi
      '';

    # Org-wide GitHub security alert reads (greater-goods + gg-engineering
    # + gg-devops + gg-sandboxes). Consumed by the Cowork morning-digest
    # dashboard at ~/Documents/Claude/Projects/Security Alerts/.
    home.activation.deployGithubSecurityPat = mkPatDeployer {
      name = "github-security-pat";
      encFile = ../../secrets/github-security-pat.enc;
      destinations = [
        "${homeDir}/Documents/Claude/Projects/Security Alerts/.github-pat"
      ];
    };

    # Repo-scoped PAT for GG-Sandboxes/james.maes — lets Cowork dashboards
    # push code, configure Pages, etc. in that sandbox repo. Lands at
    # `.github-deploy-pat` (the filename the morning-digest dashboard's
    # refresh.sh / snapshot.sh expect). Add a destination to the list
    # whenever a new Cowork project needs write access; the deployer
    # skips folders that don't exist yet.
    home.activation.deployGithubSandboxPat = mkPatDeployer {
      name = "github-sandbox-pat";
      encFile = ../../secrets/github-sandbox-pat.enc;
      destinations = [
        "${homeDir}/Documents/Claude/Projects/Security Alerts/.github-deploy-pat"
        "${homeDir}/Documents/Claude/Projects/ClaudeCode Setup/.github-deploy-pat"
      ];
    };
  };
}
