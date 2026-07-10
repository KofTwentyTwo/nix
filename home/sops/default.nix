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
      else
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

        ${lib.concatMapStringsSep "\n        "
            (d: "deploy_one ${lib.escapeShellArg d}")
            destinations}
        fi
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
    # dashboard at ~/Documents/Claude/Projects/Security Alerts/, and reused as
    # the bearer token for Codex's GitHub remote MCP: the second destination
    # lands the (classic ghp_) PAT at ~/.config/secrets/github-codex-pat, which
    # zsh sources into CODEX_GITHUB_PERSONAL_ACCESS_TOKEN (see home/zsh) — the
    # env var home/codex's fixMcpServers wires bearer_token_env_var to. The
    # github MCP therefore inherits this PAT's scopes (org-wide reads); swap in
    # a dedicated secret later if narrower scopes are wanted.
    home.activation.deployGithubSecurityPat = mkPatDeployer {
      name = "github-security-pat";
      encFile = ../../secrets/github-security-pat.enc;
      destinations = [
        "${homeDir}/Documents/Claude/Projects/Security Alerts/.github-pat"
        "${homeDir}/.config/secrets/github-codex-pat"
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

    # CircleCI personal API token. Decrypted to ~/.config/secrets/circleci-token
    # (mode 0600) at activation; sourced by zsh initContent into the
    # CIRCLECI_TOKEN env var for every interactive shell. Rotate at:
    # https://app.circleci.com/settings/user/tokens, then re-encrypt with
    # `sops secrets/circleci-token.enc` and rebuild.
    # Ensure ~/.config/secrets exists before any deployer that targets it.
    # mkPatDeployer skips destinations whose parent dir is missing, so both the
    # CircleCI token and the github-codex-pat destination depend on this.
    home.activation.ensureSecretsDir =
      lib.hm.dag.entryBefore [ "deployCircleciToken" "deployGithubSecurityPat" "deployTailscaleAuthkey" "deployOpenrouterApiKey" ] ''
        mkdir -p "${homeDir}/.config/secrets"
        chmod 0700 "${homeDir}/.config/secrets"
      '';
    home.activation.deployCircleciToken = mkPatDeployer {
      name = "circleci-token";
      encFile = ../../secrets/circleci-token.enc;
      destinations = [
        "${homeDir}/.config/secrets/circleci-token"
      ];
    };

    # OpenRouter API key. Decrypted to ~/.config/secrets/openrouter-api-key
    # (mode 0600); sourced by zsh initContent into OPENROUTER_API_KEY for every
    # interactive shell (hermes-agent and anything else OpenRouter-backed).
    # Master copy: 1Password "OpenRouter" (greatergoods account). Rotate there,
    # re-encrypt with `sops secrets/openrouter-api-key.enc`, rebuild.
    home.activation.deployOpenrouterApiKey = mkPatDeployer {
      name = "openrouter-api-key";
      encFile = ../../secrets/openrouter-api-key.enc;
      destinations = [
        "${homeDir}/.config/secrets/openrouter-api-key"
      ];
    };

    # Tailscale reusable auth key (Linux/WSL only; macOS logs in via the GUI
    # app). Decrypted to a regular file that the tailscale-autoconnect systemd
    # *user* service reads (see home/tailscale/default.nix). Double-guarded:
    # Linux-only, AND only when the encrypted secret actually exists — mkIf's
    # content is lazy, so the path literal below is never forced until the key
    # has been minted + `git add`-ed, keeping the flake green in the meantime.
    # Depends on ensureSecretsDir (listed in its entryBefore above).
    home.activation.deployTailscaleAuthkey = lib.mkIf
      (pkgs.stdenv.isLinux && builtins.pathExists ../../secrets/tailscale-authkey.enc)
      (mkPatDeployer {
        name = "tailscale-authkey";
        encFile = ../../secrets/tailscale-authkey.enc;
        destinations = [
          "${homeDir}/.config/secrets/tailscale-authkey"
        ];
      });
  };
}
