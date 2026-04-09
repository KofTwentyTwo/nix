# OpenCode Configuration Module
# =============================
# Manages OpenCode AI coding agent configuration.
# Config: ~/.config/opencode/opencode.json
# Docs: https://opencode.ai/docs/config/

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # MCP Servers - opencode uses type "local" (not "stdio"), "command" is an array
  # of [command, ...args], and env is "environment" as {KEY: VALUE} object
  mcpServers = {
    github = {
      type = "local";
      command = [ "npx" "-y" "@modelcontextprotocol/server-github" ];
      environment = {
        GITHUB_TOKEN = "$" + "{GITHUB_TOKEN}";
      };
    };
    circleci-mcp-server = {
      type = "local";
      command = [ "npx" "-y" "@circleci/mcp-server-circleci@latest" ];
      environment = {
        CIRCLECI_TOKEN = "$" + "{CIRCLECI_TOKEN}";
      };
    };
  };

  opencodeConfig = {
    mcp = mcpServers;
  };

  configJson = builtins.toJSON opencodeConfig;
in
{
  # Write opencode config via activation script (writable, not symlinked)
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CONFIG_DIR="${homeDir}/.config/opencode"
    CONFIG_FILE="$CONFIG_DIR/opencode.json"
    mkdir -p "$CONFIG_DIR"

    # Write managed config
    cat > "$CONFIG_FILE" << 'JSONEOF'
${configJson}
JSONEOF
  '';
}
