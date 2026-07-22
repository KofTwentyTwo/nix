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

  # Gemini settings. MCP servers are the shared non-Claude-agent set (github,
  # circleci, atlassian, firecrawl, context7) — see home/lib/mcp-servers.nix
  # for the auth/env-inheritance model and the Windows cmd/c wrapping.
  mcp = import ../lib/mcp-servers.nix { inherit lib; };

  geminiSettings = {
    ui = {
      theme = "dark";
    };
    # gemini ≥0.50 suppresses MCP servers in untrusted folders by default.
    # Single-operator machines: disable folder-trust gating (parity with the
    # pre-0.50 behavior the WSL/mac sides had when MCP was verified).
    security = {
      folderTrust = {
        enabled = false;
      };
    };
    mcpServers = mcp.servers;
  };
  winGeminiSettings = geminiSettings // { mcpServers = mcp.winServers; };

  geminiSettingsJson = pkgs.writeText "gemini-settings.json" (builtins.toJSON geminiSettings);
  winGeminiSettingsJson = pkgs.writeText "gemini-settings-windows.json" (builtins.toJSON winGeminiSettings);
in
{
  # GEMINI.md - read-only symlink
  home.file.".gemini/GEMINI.md".text =
    (import ../lib/agent-context.nix).mkAgentHierarchyDoc { selfRef = "GEMINI.md"; selfName = "GEMINI.md"; };

  # Install the mcp-atlassian uv tool (the atlassian MCP server entrypoint used
  # by gemini + antigravity). Idempotent — uv tool install re-resolves without
  # error. WSL/mac only; Windows installs it via windows/apply.ps1. Skips
  # cleanly if uv isn't on PATH yet.
  home.activation.installMcpAtlassian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v uv >/dev/null 2>&1; then
      uv tool install mcp-atlassian >/dev/null 2>&1 \
        && echo "[mcp] mcp-atlassian uv tool installed/current" \
        || echo "[mcp] WARN: uv tool install mcp-atlassian failed" >&2
    else
      echo "[mcp] uv not on PATH; skipping mcp-atlassian install" >&2
    fi
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
        | .security = ((.security // {}) * ($settings[0].security // {}))
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

  # LORE bridge: mirror GEMINI.md + the same settings merge into Windows-native
  # %USERPROFILE%\.gemini (gemini-cli is Node, resolves ~ to the Windows
  # profile; installed via windows/npm.json). --no-preserve strips store modes
  # (drvfs maps 0444 to the Windows READ-ONLY attribute).
  home.activation.syncWindowsGemini = lib.mkIf pkgs.stdenv.isLinux (lib.hm.dag.entryAfter [ "syncGeminiSettings" ] ''
    win="/mnt/c/Users/james/.gemini"
    if [ -d "/mnt/c/Users/james" ]; then
      mkdir -p "$win"
      cp -Lf --no-preserve=mode,ownership "${homeDir}/.gemini/GEMINI.md" "$win/GEMINI.md" 2>/dev/null \
        || echo "[gemini-win] WARN: GEMINI.md mirror failed" >&2
      wgj="$win/settings.json"
      if [ ! -f "$wgj" ] || [ ! -s "$wgj" ]; then
        ${pkgs.jq}/bin/jq -n --slurpfile settings "${winGeminiSettingsJson}" '$settings[0]' > "$wgj"
      else
        if ${pkgs.jq}/bin/jq --slurpfile settings "${winGeminiSettingsJson}" '
          .ui = ((.ui // {}) * ($settings[0].ui // {}))
          | .security = ((.security // {}) * ($settings[0].security // {}))
          | .mcpServers = $settings[0].mcpServers
        ' "$wgj" > "$wgj.tmp" && [ -s "$wgj.tmp" ]; then
          mv "$wgj.tmp" "$wgj"
        else
          rm -f "$wgj.tmp"
        fi
      fi
      echo "[gemini-win] GEMINI.md + settings mirrored"
    fi
  '');
}
