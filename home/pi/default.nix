# Pi Coding Agent Configuration Module
# =====================================
# Configures Mario Zechner's pi coding agent (@mariozechner/pi-coding-agent),
# already installed via home/npm-globals/default.nix.
#
# Files managed:
#   - ~/.pi/agent/models.json: Providers + models (rendered from models.nix)
#   - ~/.pi/agent/SYSTEM.md:   Pi-specific behaviors
#   - ~/.pi/agent/AGENTS.md:   Pointer to ~/.ai/* chain
#
# Activation: pulls Ollama models idempotently (skips if present).
# First switch may take ~10 minutes for the ~70 GB download.

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;
  modelsData = import ./models.nix;
in
{
  home.file = {
    ".pi/agent/SYSTEM.md".source = ./SYSTEM.md;
    ".pi/agent/AGENTS.md".source = ./AGENTS.md;
    ".pi/agent/models.json".text = builtins.toJSON modelsData;

    # Extensions: TypeScript modules pi loads at startup. Sourced from this
    # flake (not the runtime ~/.pi/agent/extensions/ dir) so they propagate
    # across the fleet via git pull + darwin-rebuild switch. Add new files
    # to ./extensions/ and a matching entry here.
    ".pi/agent/extensions/safe-bash.ts".source = ./extensions/safe-bash.ts;
  };

  # Pull Ollama models idempotently. First switch may take ~10 minutes for the
  # full ~60 GB download; subsequent switches skip existing models in seconds.
  # Non-fatal: continues activation even if a pull fails (offline, etc).
  home.activation.pullPiModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Home Manager activation runs with a minimal PATH. Augment with:
    #   /usr/local/bin   - where the ollama-app cask drops its CLI
    #   /opt/homebrew/bin - where the ollama brew formula would live
    #   /usr/bin /bin    - system tools (awk, grep) the idempotency check uses
    export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

    if command -v ollama >/dev/null 2>&1; then
      for m in qwen3-coder:30b qwen2.5-coder:7b llama3.3:70b-instruct-q4_K_M; do
        # Exact-name match on the NAME column to avoid prefix false-positives
        # between similar tags (e.g. q6_k vs q8_0).
        if ! ollama list 2>/dev/null | awk '{print $1}' | grep -Fxq "''${m}"; then
          echo "pi: pulling Ollama model ''${m} (may take several minutes)"
          $DRY_RUN_CMD ollama pull "''${m}" || \
            echo "pi: WARN pull of ''${m} failed; continuing" >&2
        fi
      done
    else
      echo "pi: WARN ollama not on PATH; skipping model pulls" >&2
    fi
  '';

  # ~/.pi/agent/settings.json - jq-merge nix-managed prefs while preserving
  # pi-written state (e.g. lastChangelogVersion). Defensive: never overwrite
  # the file with empty output if jq fails. Same idiom as home/claude's
  # syncClaudeSettings activation.
  #
  # Managed keys:
  #   warnings.anthropicExtraUsage = false  (suppress the Extra Usage
  #     reminder shown every time Anthropic subscription auth is used —
  #     informational, not a billing change. See pi docs/settings.md.)
  home.activation.syncPiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_json="${homeDir}/.pi/agent/settings.json"
    mkdir -p "${homeDir}/.pi/agent"

    if [ ! -f "$settings_json" ] || [ ! -s "$settings_json" ]; then
      ${pkgs.jq}/bin/jq -n '{ warnings: { anthropicExtraUsage: false } }' > "$settings_json"
      chmod 600 "$settings_json"
    else
      if ${pkgs.jq}/bin/jq '.warnings.anthropicExtraUsage = false' "$settings_json" > "$settings_json.tmp" \
        && [ -s "$settings_json.tmp" ]; then
        mv "$settings_json.tmp" "$settings_json"
        chmod 600 "$settings_json"
      else
        rm -f "$settings_json.tmp"
      fi
    fi
  '';
}
