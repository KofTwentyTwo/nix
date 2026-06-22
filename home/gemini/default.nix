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
  home.file.".gemini/GEMINI.md".text =
    (import ../lib/agent-context.nix).mkAgentHierarchyDoc { selfRef = "GEMINI.md"; selfName = "GEMINI.md"; };

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
