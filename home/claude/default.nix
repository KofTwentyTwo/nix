# Claude Code Configuration Module
# ================================
# Manages all Claude Code configuration files.
#
# Files managed:
#   - ~/.claude.json: MCP servers (activation script, writable)
#   - ~/.claude/settings.local.json: Permissions (activation script, writable)
#   - ~/.claude/CLAUDE.md: User-level memory (symlink, read-only)

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # MCP Servers - consistent across machines
  mcpServers = {
    github = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
      env = {
        GITHUB_TOKEN = "$" + "{GITHUB_TOKEN}";
      };
    };
    qqq-mcp = {
      type = "http";
      url = "http://localhost:8080/mcp";
    };
  };

  # Permissions - consistent across machines
  permissions = {
    allow = [
      "Bash(/opt/homebrew/bin/markdownlint-cli2:*)"
    ];
  };

  mcpServersJson = pkgs.writeText "mcp-servers.json" (builtins.toJSON mcpServers);
  permissionsJson = pkgs.writeText "permissions.json" (builtins.toJSON permissions);
in
{
  # CLAUDE.md - read-only symlink is fine
  home.file.".claude/CLAUDE.md".text = ''
    # Global Development Context

    See @~/.ai/0-init.md for initialization guidelines
    See @~/.ai/1-profile.md for profile information
    See @~/.ai/2-coding-style.md for coding style standards
    See @~/.ai/3-rules.md for development rules
    See @~/.ai/4-preferences.yaml for preferences
  '';

  # ~/.claude.json - merge mcpServers, preserve user data
  home.activation.syncClaudeJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_json="${homeDir}/.claude.json"

    if [ ! -f "$claude_json" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile mcp "${mcpServersJson}" '{ mcpServers: $mcp[0] }' > "$claude_json"
      chmod 600 "$claude_json"
    else
      ${pkgs.jq}/bin/jq --slurpfile mcp "${mcpServersJson}" '.mcpServers = $mcp[0]' "$claude_json" > "$claude_json.tmp"
      mv "$claude_json.tmp" "$claude_json"
      chmod 600 "$claude_json"
    fi
  '';

  # ~/.claude/settings.local.json - merge permissions, preserve user data
  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_json="${homeDir}/.claude/settings.local.json"

    mkdir -p "${homeDir}/.claude"

    if [ ! -f "$settings_json" ] || [ ! -s "$settings_json" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile perms "${permissionsJson}" '{ permissions: $perms[0] }' > "$settings_json"
      chmod 600 "$settings_json"
    else
      ${pkgs.jq}/bin/jq --slurpfile perms "${permissionsJson}" '.permissions = $perms[0]' "$settings_json" > "$settings_json.tmp"
      mv "$settings_json.tmp" "$settings_json"
      chmod 600 "$settings_json"
    fi
  '';
}
