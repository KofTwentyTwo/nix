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
# Auth model — ${VAR} references in each server's `env` block, NOT embedded
# secrets and NOT plain inheritance:
#   IMPORTANT (verified on LORE 2026-07-23): gemini/antigravity do NOT forward
#   their own inherited process environment to a stdio MCP child — they pass
#   ONLY that server's config `env` block (expanding ${VAR} from the agent's
#   environment). Servers that validate their token at STARTUP (e.g. figma)
#   therefore stay Disconnected under pure inheritance; lazy servers (github,
#   circleci, firecrawl) merely *appear* Connected while their token never
#   arrives. So every token server below declares `env = { NAME = "\${NAME}"; }`:
#   the literal `${NAME}` reaches the config (no secret in the Nix store), and
#   the agent expands it from its environment at spawn. The required vars must
#   be present when the agent runs:
#     - WSL/macOS: exported by home/zsh from ~/.config/secrets/* (sops).
#     - native Windows: set as user env vars by the LORE bridge
#       (SetEnvironmentVariable, see home/sops syncWindowsMcpTokens).
#   Required vars: GITHUB_PERSONAL_ACCESS_TOKEN, CIRCLECI_TOKEN,
#   ATLASSIAN_API_TOKEN, FIRECRAWL_API_KEY.
#   Optional: FIGMA_API_KEY (figma stays Disconnected without it).
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
      env = { GITHUB_PERSONAL_ACCESS_TOKEN = "\${GITHUB_PERSONAL_ACCESS_TOKEN}"; };
    };

    # CircleCI — CIRCLECI_TOKEN via the ${VAR} reference (see auth note above).
    circleci = {
      command = "npx";
      args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
      env = { CIRCLECI_TOKEN = "\${CIRCLECI_TOKEN}"; };
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
        ATLASSIAN_API_TOKEN = "\${ATLASSIAN_API_TOKEN}";
      };
    };
    atlassian-confluence = {
      command = "npx";
      args = [ "-y" "@aashari/mcp-server-atlassian-confluence" ];
      env = {
        ATLASSIAN_SITE_NAME = "greatergoods";
        ATLASSIAN_USER_EMAIL = "jmaes@greatergoods.com";
        ATLASSIAN_API_TOKEN = "\${ATLASSIAN_API_TOKEN}";
      };
    };

    # Firecrawl — reads FIRECRAWL_API_KEY from the inherited environment.
    # Stays Disconnected until secrets/firecrawl-api-key.enc exists (pending
    # credential rotation) and deploys.
    firecrawl = {
      command = "npx";
      args = [ "-y" "firecrawl-mcp@3.22.3" ];
      env = { FIRECRAWL_API_KEY = "\${FIRECRAWL_API_KEY}"; };
    };

    # Context7 — live library/API docs; keyless (rate-limited).
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };

    # ---- Visual / diagramming set (added 2026-07-23) --------------------------
    # NOTE ON PACKAGE NAMES: the request that prompted this used
    # `@figma/mcp-server`, `@modelcontextprotocol/server-playwright`, and
    # `@modelcontextprotocol/server-plantuml` — NONE of which exist on npm
    # (verified). The real, maintained packages are used below. All four are
    # Node/npx stdio servers — the class that reloads cleanly in antigravity's
    # `/mcp` (Python/OAuth-remote servers do not; see the Atlassian note above).

    # Figma (Framelink figma-developer-mcp) — read designs, export images. Reads
    # a Figma personal access token from FIGMA_API_KEY in the environment (home/
    # zsh / home/sops), never the config. `--stdio` is REQUIRED — without it the
    # package starts an HTTP/SSE server instead of stdio. Figma's own Dev Mode
    # server is an in-app HTTP endpoint agy can't handshake, so this local Node
    # server is the right fit. Stays Disconnected until secrets/figma-api-token
    # .enc exists (same pending-token pattern as firecrawl).
    figma = {
      command = "npx";
      args = [ "-y" "figma-developer-mcp" "--stdio" ];
      env = { FIGMA_API_KEY = "\${FIGMA_API_KEY}"; };
    };

    # Playwright (Microsoft official @playwright/mcp) — headless browser driving:
    # render pages, capture screenshots/PNGs, visual diffs of HTML/SVG. No token.
    # Browsers are fetched on first navigation (`npx playwright install`); LORE
    # already has Chrome. (Claude Code has its own playwright plugin — separate;
    # this is the gemini/agy set.)
    playwright = {
      command = "npx";
      args = [ "-y" "@playwright/mcp@latest" ];
    };

    # Excalidraw (excalidraw-mcp) — create/update/query editable canvas diagram
    # elements. Works standalone in-memory over stdio (verified: create_element
    # returns an element with no backend). The package's Docker "canvas server"
    # is OPTIONAL — only for live-viewing the canvas in a browser. No token.
    excalidraw = {
      command = "npx";
      args = [ "-y" "excalidraw-mcp" ];
    };

    # PlantUML (plantuml-mcp-server) — UML class/sequence/component diagrams.
    # Renders via a REMOTE PlantUML server (no local Java): PLANTUML_SERVER_URL
    # points at the public plantuml.com renderer by default.
    # PRIVACY: diagram source is POSTed to that public server to render. For
    # proprietary/architecture diagrams, run a local PlantUML server (e.g.
    # `docker run -d -p 8080:8080 plantuml/plantuml-server`) and set
    # PLANTUML_SERVER_URL = "http://localhost:8080" here.
    plantuml = {
      command = "npx";
      args = [ "-y" "plantuml-mcp-server" ];
      env = {
        PLANTUML_SERVER_URL = "https://www.plantuml.com/plantuml";
      };
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
