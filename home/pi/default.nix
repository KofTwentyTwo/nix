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
  modelsData = import ./models.nix { inherit config lib; };
in
{
  home.file = {
    ".pi/agent/SYSTEM.md".source = ./SYSTEM.md;
    ".pi/agent/AGENTS.md".source = ./AGENTS.md;
    ".pi/agent/models.json".text = builtins.toJSON modelsData;
  };

  # Pull Ollama models idempotently. First switch may take ~10 minutes for the
  # full ~70 GB download; subsequent switches skip existing models in seconds.
  # Non-fatal: continues activation even if a pull fails (offline, etc).
  home.activation.pullPiModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v ollama >/dev/null 2>&1; then
      for m in qwen3-coder:30b-a3b-q6_k qwen2.5-coder:7b llama3.3:70b-instruct-q4_K_M; do
        if ! ollama list 2>/dev/null | grep -q "''${m}"; then
          echo "pi: pulling Ollama model ''${m} (may take several minutes)"
          $DRY_RUN_CMD ollama pull "''${m}" || \
            echo "pi: WARN pull of ''${m} failed; continuing" >&2
        fi
      done
    else
      echo "pi: WARN ollama not on PATH; skipping model pulls" >&2
    fi
  '';
}
