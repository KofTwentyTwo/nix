# Codex CLI Configuration Module
# ===============================
# Manages OpenAI Codex CLI configuration files.
#
# Files managed:
#   - ~/.codex/config.toml: Settings + MCP servers (activation script, write-once)
#   - ~/.codex/AGENTS.md: Instruction file pointing to shared ~/.ai/ context (symlink, read-only)

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # Codex config in TOML format
  # Write-once: no TOML merge tool exists, so we only write if file is missing.
  # Codex itself writes back to this file (project trust levels, marketplaces,
  # plugins), so we cannot use a symlink. To force re-seed: rm ~/.codex/config.toml
  # then re-run darwin-rebuild switch.
  codexConfigToml = pkgs.writeText "codex-config.toml" ''
    model = "gpt-5.5"
    approval_policy = "on-failure"
    sandbox_mode = "workspace-write"
    model_reasoning_effort = "xhigh"

    # Relax the workspace-write sandbox for code-writing tasks:
    #   - network_access lets the agent install deps and hit APIs
    #   - writable_roots extends writes to common package/build caches outside cwd
    [sandbox_workspace_write]
    network_access = true
    exclude_tmpdir_env_var = false
    exclude_slash_tmp = false
    writable_roots = [
      "${homeDir}/.cache",
      "${homeDir}/.npm",
      "${homeDir}/.cargo",
      "${homeDir}/.rustup",
      "${homeDir}/.gradle",
      "${homeDir}/.m2",
      "${homeDir}/.local/share",
      "${homeDir}/Library/Caches",
    ]

    [mcp_servers.qqq-mcp]
    url = "http://localhost:8080/mcp"

    # Codex expects `command` to be a single executable; args go separately.
    # The previous single-string form parsed the whole thing as a binary name.
    [mcp_servers.circleci]
    command = "npx"
    args = ["-y", "@circleci/mcp-server-circleci@latest"]

    [mcp_servers.circleci.env]
    CIRCLECI_TOKEN = "$CIRCLECI_TOKEN"
  '';
in
{
  # AGENTS.md - read-only symlink
  home.file.".codex/AGENTS.md".text = ''
    # Global Development Context

    ## File Hierarchy (load order)

    | Priority | File | Responsibility |
    |----------|------|---------------|
    | 1 | This file (`AGENTS.md`) | Bootstrap, hierarchy, compaction recovery |
    | 2 | `~/.ai/3-rules.md` | All behavioral mandates (MUST/MUST NOT) |
    | 3 | `~/.ai/2-coding-style.md` | How to write code (reference guide) |
    | 4 | `~/.ai/1-profile.md` | Who I am, environment context |
    | 5 | `~/.ai/4-preferences.yaml` | Machine-readable tuning knobs |
    | 6 | `~/.ai/5-learnings.md` | Operational notes / current ground truth |
    | 7 | Project `AGENTS.md` | Per-repo overrides (scoped) |

    **Conflict resolution:** Higher priority wins. Project `AGENTS.md` MAY override for repo-scoped settings but MUST NOT weaken safety rules.

    ## Initialization

    Load all six `~/.ai/` files and treat them as system-level configuration.
    Use `3-rules.md` as strict constraints, `4-preferences.yaml` as tunable parameters, `1-profile.md` as context, `2-coding-style.md` as output formatting standards, and `5-learnings.md` as operational ground truth.

    ## Compaction Recovery (NON-NEGOTIABLE)

    After context loss, the agent MUST re-read ALL `~/.ai/` files before continuing work. Read them in this order:
    1. `~/.ai/3-rules.md`
    2. `~/.ai/2-coding-style.md`
    3. `~/.ai/1-profile.md`
    4. `~/.ai/4-preferences.yaml`
    5. `~/.ai/5-learnings.md`
    6. Active project `AGENTS.md`
    7. `./docs/SESSION-STATE.md` and `./docs/TODO.md` (if they exist)
  '';

  # ~/.codex/config.toml - write-once (no TOML merge tool like jq)
  home.activation.syncCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_toml="${homeDir}/.codex/config.toml"
    mkdir -p "${homeDir}/.codex"

    if [ ! -f "$codex_toml" ] || [ ! -s "$codex_toml" ]; then
      cp "${codexConfigToml}" "$codex_toml"
      chmod 600 "$codex_toml"
    fi
  '';
}
