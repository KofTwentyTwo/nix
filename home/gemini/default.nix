# Gemini CLI Configuration Module
# ================================
# Manages Google Gemini CLI configuration files.
#
# Files managed:
#   - ~/.gemini/settings.json: Settings + MCP servers (activation script, writable)
#   - ~/.gemini/GEMINI.md: Instruction file pointing to shared ~/.ai/ context (symlink, read-only)

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # Gemini settings with MCP servers
  geminiSettings = {
    ui = {
      theme = "dark";
    };
    mcpServers = {
      qqq-mcp = {
        httpUrl = "http://localhost:8080/mcp";
      };
      circleci = {
        command = "npx";
        args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
        env = {
          CIRCLECI_TOKEN = "$" + "{CIRCLECI_TOKEN}";
        };
      };
    };
  };

  geminiSettingsJson = pkgs.writeText "gemini-settings.json" (builtins.toJSON geminiSettings);
in
{
  # GEMINI.md - read-only symlink
  home.file.".gemini/GEMINI.md".text = ''
    # Global Development Context

    ## File Hierarchy (load order)

    | Priority | File | Responsibility |
    |----------|------|---------------|
    | 1 | This file (`GEMINI.md`) | Bootstrap, hierarchy, compaction recovery |
    | 2 | `~/.ai/3-rules.md` | All behavioral mandates (MUST/MUST NOT) |
    | 3 | `~/.ai/2-coding-style.md` | How to write code (reference guide) |
    | 4 | `~/.ai/1-profile.md` | Who I am, environment context |
    | 5 | `~/.ai/4-preferences.yaml` | Machine-readable tuning knobs |
    | 6 | Project `GEMINI.md` | Per-repo overrides (scoped) |

    **Conflict resolution:** Higher priority wins. Project `GEMINI.md` MAY override for repo-scoped settings but MUST NOT weaken safety rules.

    ## Initialization

    Load all four `~/.ai/` files and treat them as system-level configuration.
    Use `3-rules.md` as strict constraints, `4-preferences.yaml` as tunable parameters, `1-profile.md` as context, and `2-coding-style.md` as output formatting standards.

    ## Compaction Recovery (NON-NEGOTIABLE)

    After context compaction, the agent MUST re-read ALL `~/.ai/` files before continuing work. Compaction discards these files from context. Read them in this order:
    1. `~/.ai/3-rules.md`
    2. `~/.ai/2-coding-style.md`
    3. `~/.ai/1-profile.md`
    4. `~/.ai/4-preferences.yaml`
    5. Active project `GEMINI.md`
    6. `./docs/SESSION-STATE.md` and `./docs/TODO.md` (if they exist)
  '';

  # ~/.gemini/settings.json - merge settings, preserve user data
  home.activation.syncGeminiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    gemini_json="${homeDir}/.gemini/settings.json"
    mkdir -p "${homeDir}/.gemini"

    if [ ! -f "$gemini_json" ] || [ ! -s "$gemini_json" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile settings "${geminiSettingsJson}" '$settings[0]' > "$gemini_json"
      chmod 600 "$gemini_json"
    else
      if ${pkgs.jq}/bin/jq --slurpfile settings "${geminiSettingsJson}" '
        .ui = ((.ui // {}) * ($settings[0].ui // {}))
        | .mcpServers = $settings[0].mcpServers
      ' "$gemini_json" > "$gemini_json.tmp" \
        && [ -s "$gemini_json.tmp" ]; then
        mv "$gemini_json.tmp" "$gemini_json"
        chmod 600 "$gemini_json"
      else
        rm -f "$gemini_json.tmp"
      fi
    fi
  '';
}
