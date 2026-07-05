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
  # Global rules: same shared bootstrap doc as Claude/Codex/Gemini (file
  # hierarchy, ~/.ai loading, second-brain directive, compaction recovery).
  # opencode reads ~/.config/opencode/AGENTS.md as its global rules file.
  home.file.".config/opencode/AGENTS.md".text =
    (import ../lib/agent-context.nix).mkAgentHierarchyDoc {
      selfRef = "~/.config/opencode/AGENTS.md";
      selfName = "AGENTS.md";
    };

  # Skills need no wiring: opencode natively reads the Claude-compatible
  # global skills tree at ~/.claude/skills/<name>/SKILL.md, which
  # home/claude/skills.nix (WSL/mac) and the LORE Windows bridge already
  # populate. One skills tree, every agent.

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

  # LORE bridge: mirror opencode config + rules + auth into Windows-native
  # %USERPROFILE%\.config\opencode (opencode resolves ~ to the Windows profile)
  # and persist SECOND_BRAIN_VAULT as a Windows user env var so non-Claude
  # agents see the vault path (Claude gets it via settings.json env instead).
  home.activation.syncWindowsOpencode = lib.mkIf pkgs.stdenv.isLinux (lib.hm.dag.entryAfter [ "opencodeConfig" "opencodeAuth" ] ''
    winHome="/mnt/c/Users/james"
    if [ -d "$winHome" ]; then
      mkdir -p "$winHome/.config/opencode" "$winHome/.local/share/opencode"
      cp -f  "${homeDir}/.config/opencode/opencode.json" "$winHome/.config/opencode/opencode.json" 2>/dev/null \
        && echo "[opencode-win] opencode.json mirrored" \
        || echo "[opencode-win] WARN: opencode.json mirror failed" >&2
      cp -Lf "${homeDir}/.config/opencode/AGENTS.md" "$winHome/.config/opencode/AGENTS.md" 2>/dev/null \
        || echo "[opencode-win] WARN: AGENTS.md mirror failed" >&2
      # Auth: mirror WSL auth.json only if Windows has none yet (never clobber
      # tokens minted by `opencode auth login` on the Windows side).
      if [ -f "${homeDir}/.local/share/opencode/auth.json" ] && [ ! -f "$winHome/.local/share/opencode/auth.json" ]; then
        cp -f "${homeDir}/.local/share/opencode/auth.json" "$winHome/.local/share/opencode/auth.json" 2>/dev/null \
          && echo "[opencode-win] auth.json seeded from WSL" || true
      fi
      # Persistent user env var for the vault (idempotent; setx overwrites).
      /mnt/c/Windows/System32/cmd.exe /c 'setx SECOND_BRAIN_VAULT "R:\Git.Local\KofTwentyTwo\second-brain"' >/dev/null 2>&1 \
        && echo "[opencode-win] SECOND_BRAIN_VAULT user env var set" \
        || echo "[opencode-win] WARN: setx SECOND_BRAIN_VAULT failed" >&2
    fi
  '');

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
