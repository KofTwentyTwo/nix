# OpenCode Configuration Module
# =============================
# Manages OpenCode AI coding agent configuration.
# Config: ~/.config/opencode/opencode.json
# Docs: https://opencode.ai/docs/config/

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # MCP Servers - shared with Claude Code
  mcpServers = {
    github = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
      env = {
        GITHUB_TOKEN = "$" + "{GITHUB_TOKEN}";
      };
    };
    circleci-mcp-server = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
      env = {
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
