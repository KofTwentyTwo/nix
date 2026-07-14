# PLAN: Claude Code Global Setup + Obsidian Second Brain

**Source spec:** `claude-code-secondbrain-requirements.md` (James, July 2026 — delivered via Claude desktop session outputs).
**Status:** implementing 2026-07-03 on LORE. Decisions below taken with James AFK (recommended defaults).

## Gap analysis vs the spec

Already satisfied by this repo (no work needed):

- §A2 settings.json Nix-generated (`home/claude/default.nix` syncClaudeUserSettings).
- §A3 secrets via sops-nix, env-var contract pattern established.
- §B1 marketplaces pinned declaratively (`installClaudePluginMarketplaces`).
- §B2 LSPs: clangd/gopls/jdtls/kotlin/pyright/rust-analyzer/swift/typescript already enabled. **Gap:** `csharp-lsp` (exists in official marketplace → add). No HCL/Terraform LSP exists upstream (documented gap).
- §B3 workflow skills: pr-review-toolkit, superpowers, frontend-design, code-review already on. **Gap:** HashiCorp coverage → official `terraform` plugin exists but is an MCP server → declared **false** (swap-in, budget).
- §B4 core MCP: Context7/GitHub/Atlassian already ship as enabled plugins. Non-plugin always-on stdio servers: circleci-mcp-server, ruflo, sonarqube(settings-scope). qqq-mcp already removed previously.

## Decisions (user AFK — recommended options)

1. **Vault:** NEW at `R:\Git.Local\KofTwentyTwo\second-brain` (Windows) = `/mnt/r/Git.Local/KofTwentyTwo/second-brain` (WSL) = `~/Git.Local/KofTwentyTwo/second-brain` (Macs, cloned). Obsidian on LORE via winget (`Obsidian.Obsidian`).
2. **Remote:** private GitHub `KofTwentyTwo/second-brain`, created via gh.
3. **MCP budget:** core-3-as-plugins stay; stdio swap-ins (circleci, ruflo, sonarqube, terraform-plugin) documented + count-asserted in sync activation (warn > 5).
4. **Scope:** all three surfaces — WSL + Macs via `home/secondbrain/`, Windows Claude Code via a LORE-only bridge activation writing into `/mnt/c/Users/james/.claude`.

## New module: `home/secondbrain/default.nix`

- `home.sessionVariables.SECOND_BRAIN_VAULT` (per-OS path as above).
- Vault bootstrap activation: if missing, clone the remote. If the clone is unavailable, create an unversioned scaffold plus a pending marker. Later activations retry the clone, replace only an untouched scaffold, and preserve authored offline content for explicit merge. Idempotent and non-destructive.
- Hook scripts (bash, Nix-managed, fail-safe `exit 0` always):
  - `secondbrain-session-start.sh`: emit `index.md` + `projects/<repo>.md` (repo detected from cwd git remote/basename) + one-line convention reminder.
  - `secondbrain-session-end.sh`: append a stub line to `daily/YYYY-MM-DD.md` (timestamp, cwd, branch) — the *content* writes are the model's job via skill + CLAUDE.md directive.
- Skills (home.file into `~/.claude/skills/`): `secondbrain-save` (write conventions: ADR to decisions/, project state append, knowledge notes, daily log; frontmatter created/updated/tags/source; append-only; link from index.md) and `secondbrain-consolidate` (dedupe, fix links, trim index, commit+push).
- Consolidation schedule: systemd user timer (Linux) / launchd agent (mac), weekly, `claude -p` headless with fixed prompt invoking the consolidate skill; idempotent; `|| true` fail-safe; logs to ~/.local/state.

## Changes: `home/claude/default.nix` + `home/lib/agent-context.nix`

- agent-context doc gains a concise "Second Brain" section (vault path env var, read-on-start, save-on-end via secondbrain-save) — flows to Claude/Codex/Gemini bootstrap files identically.
- settings sync: add `env.SECOND_BRAIN_VAULT` and hook entries. Hooks merged **by marker** (drop existing entries containing `secondbrain`, append ours) so GSD-managed hooks on Macs are never clobbered.
- MCP count assert: warn during sync if mcpServers count > 5.
- enabledPlugins: + `csharp-lsp@claude-plugins-official` = true; + `terraform@claude-plugins-official` = false (swap-in note).

## Windows bridge (LORE only)

`home/secondbrain` activation guarded by `/mnt/c/Users/james/.claude` existing:
- copies CLAUDE.md content, PowerShell ports of the two hooks, skills tree;
- merges `env.SECOND_BRAIN_VAULT` + hook entries into `%USERPROFILE%\.claude\settings.json` via jq (marker-based, non-destructive).

## Acceptance (§9) — to run after switch

1. hooks fire: `claude` from empty dir shows index.md injection. 2. `/mcp` count ≤ 5. 3. decision-write test via skill. 4. consolidate twice → idempotent. 5. secret scan of vault + configs. 6. LSP diagnostics spot-check (existing plugins). Results recorded in SESSION-STATE.

## Open items for James

- Confirm vault location/remote choice (moving later = edit one Nix path + `git remote set-url`).
- Sentry/K8s MCP swap-ins: not configured (no evidence of Sentry use in repo); add on request.
- macOS: first `darwin-rebuild switch` after pull will clone the vault; needs SSH/gh auth present (already standard on Macs).
