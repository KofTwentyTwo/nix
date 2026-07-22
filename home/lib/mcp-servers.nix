# Shared MCP server definitions for the non-Claude terminal agents
# =================================================================
# Consumed by home/gemini (settings.json `mcpServers`) and home/antigravity
# (~/.gemini/config/mcp_config.json `mcpServers`). Claude Code gets these via
# its plugin marketplace; codex/opencode/hermes carry their own sets. Defining
# the gemini/antigravity set once here keeps the two in lockstep.
#
# All servers use stdio (npx) transport so one definition works for both agents
# on macOS, WSL, and native Windows. Remote services are reached through
# `mcp-remote`, which proxies an HTTP/SSE endpoint over stdio.
#
# Auth model — env inheritance, NOT config-embedded secrets:
#   The npx child inherits the launching agent's environment. We deliberately
#   do NOT write token values into these (Nix-store, world-readable) configs.
#   Instead the required env vars must be present when the agent runs:
#     - WSL/macOS: exported by home/zsh from ~/.config/secrets/* (sops).
#     - native Windows: set as user env vars by the LORE bridges (setx from the
#       same deployed secret files).
#   Required vars: GITHUB_TOKEN, CIRCLECI_TOKEN, FIRECRAWL_API_KEY.
#   `mcp-remote` expands ${GITHUB_TOKEN} in the header; the circleci/firecrawl
#   servers read their env vars directly from the inherited environment.
#
# Atlassian is OAuth (authv2) — first use opens a browser consent; no token.
# Context7 works keyless (rate-limited); add CONTEXT7_API_KEY to the env later
# for higher limits.
{ }:
{
  # GitHub — official remote MCP (maintained; the npm server-github is archived).
  github = {
    command = "npx";
    args = [
      "-y" "mcp-remote@0.1.38"
      "https://api.githubcopilot.com/mcp/"
      "--header" "Authorization: Bearer \${GITHUB_TOKEN}"
    ];
  };

  # CircleCI — reads CIRCLECI_TOKEN from the inherited environment.
  circleci = {
    command = "npx";
    args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
  };

  # Atlassian (Jira/Confluence) — remote OAuth; browser consent on first use.
  atlassian = {
    command = "npx";
    args = [ "-y" "mcp-remote@0.1.38" "https://mcp.atlassian.com/v1/mcp/authv2" ];
  };

  # Firecrawl — reads FIRECRAWL_API_KEY from the inherited environment.
  firecrawl = {
    command = "npx";
    args = [ "-y" "firecrawl-mcp@3.22.3" ];
  };

  # Context7 — live library/API docs; keyless (rate-limited).
  context7 = {
    command = "npx";
    args = [ "-y" "@upstash/context7-mcp" ];
  };
}
