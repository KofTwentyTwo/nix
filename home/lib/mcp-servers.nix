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
# Atlassian is OAuth (authv2) — consent already done on LORE; mcp-remote's
# auth cache (~/.mcp-auth) is NAMESPACED BY mcp-remote VERSION, so the pin
# below must stay 0.1.37 (where the existing Atlassian tokens live) unless
# you're prepared to redo the browser consent after bumping.
# Context7 works keyless (rate-limited); add CONTEXT7_API_KEY to the env later
# for higher limits.
#
# Returns { servers, winServers }:
#   servers    — plain npx spawns (macOS/WSL; POSIX exec finds `npx` fine).
#   winServers — identical set wrapped in `cmd /c`: neither Go (antigravity)
#                nor Node 20+ (gemini) can spawn `.cmd` shims like npx.cmd
#                directly on Windows (CreateProcess / Node CVE-2024-27980
#                hardening). Same pattern Claude Code's own Windows config
#                uses. Use winServers for every Windows-side mirror.
{ lib }:
let
  servers = {
    # GitHub — LOCAL stdio server (reads GITHUB_PERSONAL_ACCESS_TOKEN from the
    # environment). NOT the Copilot remote via mcp-remote: against
    # api.githubcopilot.com, mcp-remote runs an OAuth *discovery* flow
    # (github.com/login/oauth) that hangs antigravity at "initializing…" even
    # with a valid static bearer header. The classic npm server is archived but
    # functional and handshakes normally like the other local stdio servers.
    github = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
    };

    # CircleCI — reads CIRCLECI_TOKEN from the inherited environment.
    circleci = {
      command = "npx";
      args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
    };

    # Atlassian (Jira + Confluence) — NODE servers (@aashari), one per product.
    # History (all reproduced on LORE): the OAuth remote (mcp.atlassian.com)
    # rejects agy's server/discover-first handshake (HTTP 400); the Python
    # `mcp-atlassian` connects on fresh start but agy's `/mcp` RELOAD can't
    # cleanly stop it — first "i.CS.Close() did not return within 100ms after
    # SIGKILL", then "exit status 1". The OBSERVED pattern across all servers:
    # Node/npx MCP servers reload cleanly in agy (circleci/github/context7/
    # firecrawl all do); the Python one never does. So Jira+Confluence now use
    # the Node @aashari servers — same class as the working four. Auth: account-
    # wide ATLASSIAN_API_TOKEN from the environment (home/zsh / home/sops);
    # SITE_NAME + USER_EMAIL are non-secret literals.
    atlassian-jira = {
      command = "npx";
      args = [ "-y" "@aashari/mcp-server-atlassian-jira" ];
      env = {
        ATLASSIAN_SITE_NAME = "greatergoods";
        ATLASSIAN_USER_EMAIL = "jmaes@greatergoods.com";
      };
    };
    atlassian-confluence = {
      command = "npx";
      args = [ "-y" "@aashari/mcp-server-atlassian-confluence" ];
      env = {
        ATLASSIAN_SITE_NAME = "greatergoods";
        ATLASSIAN_USER_EMAIL = "jmaes@greatergoods.com";
      };
    };

    # Firecrawl — reads FIRECRAWL_API_KEY from the inherited environment.
    # Stays Disconnected until secrets/firecrawl-api-key.enc exists (pending
    # credential rotation) and deploys.
    firecrawl = {
      command = "npx";
      args = [ "-y" "firecrawl-mcp@3.22.3" ];
    };

    # Context7 — live library/API docs; keyless (rate-limited).
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
  };
in
{
  inherit servers;
  # Windows: wrap ONLY the `.cmd` shims (npx/npm/uvx) in `cmd /c` — Go
  # (antigravity) and Node 20+ (gemini) can't spawn `.cmd` directly. Real `.exe`
  # entrypoints (e.g. the uv-tool `mcp-atlassian` shim) are spawned DIRECTLY:
  # the `cmd /c` wrapper adds a cmd.exe parent that agy's /mcp reload kills
  # while the real child survives holding the stdio pipe (100ms-SIGKILL timeout
  # → "i.CS.Close() did not return", atlassian dropped). Spawning the .exe
  # directly gives agy a single process it can terminate cleanly.
  winServers = lib.mapAttrs
    (_: s:
      if builtins.elem s.command [ "npx" "npm" "uvx" ]
      then (removeAttrs s [ "command" "args" ]) // {
        command = "cmd";
        args = [ "/c" s.command ] ++ s.args;
      }
      else s)
    servers;
}
