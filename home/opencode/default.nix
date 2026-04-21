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

  # Ollama provider for local models
  providers = {
    ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options = {
        baseURL = "http://localhost:11434/v1";
      };
      models = {
        "qwen3.5:35b-a3b-coding-nvfp4" = {
          name = "Qwen 3.5 Coder 35B";
        };
      };
    };
  };

  opencodeConfig = {
    provider = providers;
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

  # Write auth config for Ollama (dummy key - Ollama doesn't validate)
  home.activation.opencodeAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    AUTH_DIR="${homeDir}/.local/share/opencode"
    AUTH_FILE="$AUTH_DIR/auth.json"
    mkdir -p "$AUTH_DIR"

    # Only write if no auth.json exists or if it doesn't have ollama configured
    if [ ! -f "$AUTH_FILE" ] || ! ${pkgs.jq}/bin/jq -e '.ollama' "$AUTH_FILE" > /dev/null 2>&1; then
      # Merge with existing auth if present, otherwise create new
      if [ -f "$AUTH_FILE" ]; then
        ${pkgs.jq}/bin/jq '. + {"ollama": {"type": "api", "key": "ollama"}}' "$AUTH_FILE" > "$AUTH_FILE.tmp" && mv "$AUTH_FILE.tmp" "$AUTH_FILE"
      else
        cat > "$AUTH_FILE" << 'AUTHEOF'
{"ollama":{"type":"api","key":"ollama"}}
AUTHEOF
      fi
    fi
  '';
}
