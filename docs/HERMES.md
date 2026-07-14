# Hermes Agent

Hermes is the primary cross-platform coding agent in this repository. Home Manager installs it on macOS and WSL, while `windows/apply.ps1` installs the native Windows runtime. Every declared runtime receives the same tracked policy, identity, AI files, Second Brain skills, and OpenRouter routing. The managed overlay lives at `~/.config/hermes-managed` on Unix and `%LOCALAPPDATA%\hermes\managed` on Windows. Its user-owned scope prevents accidental local drift but is not an administrator-enforced security boundary.

## Capability status

| Capability | Declarative source | Current status |
|---|---|---|
| OpenRouter model selection | `home/hermes/managed-config.yaml` | Live verified with `openrouter/pareto-code` through OpenRouter |
| AI context | `home/ai/`, `home/hermes/SOUL.md` | Live on the current Mac and WSL; declared for native Windows pending LORE validation |
| Second Brain | `home/secondbrain/` | Read and write skills deployed; durable Nix and Hermes notes recorded |
| Git and GitHub code | SSH, `gh`, and SOPS-managed `GITHUB_TOKEN` | Live repository and workflow API access verified as `KofTwentyTwo` |
| CircleCI | SOPS token plus `circleci` | Live diagnostic works, but the exposed token must be rotated before trusted use |
| Jira and Confluence | Hermes Atlassian MCP plus `confluence.sh` | MCP connected and tools discovered |
| Firecrawl | SOPS key plus pinned `firecrawl-mcp` | Declared for Hermes, Claude Code, and Codex; 1Password item exists but its credential is empty |
| Local shell and files | Hermes terminal backend | Live verified by a Hermes `pwd` tool invocation |
| Computer use | Hermes CUA driver | Live desktop capture verified on the current Mac with Accessibility and Screen Recording granted |
| Greater Goods Slack | SOPS tokens plus generated app manifest | Declarative, awaiting workspace app creation and tokens |
| Gmail and Google Workspace | Bundled skill plus SOPS Desktop OAuth client | Declarative, awaiting Google Cloud client creation and per-runtime consent |

Safe reads and ordinary local development commands do not require repeated confirmation. Commits, pushes, outbound messages, infrastructure changes, secret-bearing actions, destructive actions, and forced Git history changes remain governed by `~/.ai/3-rules.md`. Checkpoints are enabled, and force pushes, hard resets, and forced cleans are denied by managed policy.

## Runtime ownership

Every host may run interactive Hermes. Grogu alone owns the continuously running Slack Socket Mode gateway, selected by `machineConfigs.<host>.hermesGateway` in `flake.nix`. Slack service credentials deploy only to Grogu; non-owner Unix and Windows services are removed. The launch agent receives `HERMES_HOME` and `HERMES_MANAGED_DIR`, starts at login, and checks every five minutes until its credentials are ready.

## Activate and validate

The rollout is committed and pushed to `origin/main`. Validate and activate the current tree with:

```bash
sudo darwin-rebuild check --flake path:.
sudo darwin-rebuild switch --flake path:.
```

Useful non-secret checks:

```bash
hermes --version
hermes computer-use status
hermes mcp list
hermes mcp test atlassian
hermes-google-workspace status
```

Verify GitHub repository and workflow API access with `gh auth status` and a
read-only `gh` API call. Rotate the known-exposed CircleCI personal token
before treating the live diagnostic as trusted.

On native Windows, run `windows\apply.ps1` in PowerShell, run the WSL Home Manager switch so SOPS material crosses the bridge, then rerun `windows\apply.ps1` to apply Windows ACLs and validate the installed runtime. LORE is currently offline, so this remains the only unexecuted platform validation. Unix-only tools are available through WSL when no native executable exists.

## Greater Goods Slack onboarding

The target workspace is Greater Goods, workspace ID `T11SSKDJ9`; only James's member ID `U0A31489THN` is authorized. The managed policy requires a strict mention, ignores unauthorized direct messages, and accepts any channel to which the app is explicitly invited.

1. Activate Grogu so Hermes writes `~/.config/hermes-managed/slack-manifest.json`.
2. Create the Greater Goods Slack app from that manifest, install it to the workspace, and create a Socket Mode app token with `connections:write`.
3. Store the bot and app tokens in temporary mode-0600 files, then encrypt them as `secrets/hermes-slack-bot-token.enc` and `secrets/hermes-slack-app-token.enc` using the matching SOPS rules. Never paste tokens into documentation, chat, logs, or shell history.
4. Add the encrypted files to Git, activate Grogu, invite Hermes only to intended channels, then verify the gateway log at `~/Library/Logs/hermes-gateway.log`.

## Gmail and Google Workspace onboarding

Gmail is the primary Google integration. The bundled Google Workspace skill also covers Calendar, Drive, Docs, Sheets, People, and Contacts. In Google Cloud, enable the Gmail, Calendar, Drive, Sheets, Docs, and People APIs; create a Desktop OAuth client; configure the consent screen and test user if required; then SOPS-encrypt the downloaded JSON as `secrets/hermes-google-client-secret.enc`.

After activation, authorize each runtime separately because refresh tokens stay machine-local:

```bash
hermes-google-workspace auth-url
hermes-google-workspace auth-code 'REDIRECT_URL_OR_CODE'
hermes-google-workspace status
```

Native Windows uses `windows\hermes-google-workspace.ps1` with `AuthUrl`, `AuthCode`, and `Status`. The helper applies a current-user-only ACL to OAuth files after each successful command.

## Firecrawl onboarding

Firecrawl uses the official stdio MCP server pinned as `firecrawl-mcp@3.22.3`.
Hermes, Claude Code, Codex, WSL, and native Windows all reference the same
`FIRECRAWL_API_KEY` without placing it in the Nix store. The Personal-vault
1Password item named `Firecrawl` currently has an empty credential field. Add
the subscription key to that item, retrieve it into a temporary mode-0600 file,
and SOPS-encrypt it as `secrets/firecrawl-api-key.enc`. After activation,
verify the Firecrawl MCP in all three agents with a safe search or scrape
request. The server and environment contract follow the
[official Firecrawl MCP documentation](https://docs.firecrawl.dev/mcp).
