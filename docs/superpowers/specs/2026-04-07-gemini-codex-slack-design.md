# Design: Gemini CLI + Codex CLI + Slack CLI Integration

**Date:** 2026-04-07
**Status:** Draft
**Approach:** Separate Home Manager modules (Approach 1)

## Goal

Install and fully configure Google Gemini CLI, OpenAI Codex CLI, and Slack CLI via the existing nix-darwin + Home Manager setup. Each AI tool gets Claude-level config management with MCP servers, settings, and instruction files that reference the shared `~/.ai/` context.

## Installation

All three tools installed via Homebrew in `modules/homebrew.nix`:

| Tool | Brew type | Package name | Current version |
|------|-----------|-------------|-----------------|
| Gemini CLI | formula | `gemini-cli` | 0.36.0 |
| Codex CLI | cask | `codex` | 0.118.0 |
| Slack CLI | cask | `slack-cli` | 3.15.0 |

Homebrew chosen over Nix packages because these fast-moving CLI tools get upstream releases faster via Homebrew.

## Module Structure

```
home/
  gemini/default.nix    # NEW - Gemini CLI config
  codex/default.nix     # NEW - Codex CLI config
  default.nix           # MODIFIED - add imports for gemini, codex
modules/
  homebrew.nix          # MODIFIED - add 3 packages
```

## Module 1: Gemini CLI (`home/gemini/default.nix`)

### Files Managed

| File | Method | Purpose |
|------|--------|---------|
| `~/.gemini/settings.json` | Activation script (writable) | Settings + MCP servers |
| `~/.gemini/GEMINI.md` | Symlink (read-only) | Instruction file |

### Settings (`~/.gemini/settings.json`)

```json
{
  "ui": {
    "theme": "dark"
  },
  "mcpServers": {
    "qqq-mcp": {
      "httpUrl": "http://localhost:8080/mcp"
    },
    "circleci": {
      "command": "npx",
      "args": ["-y", "@circleci/mcp-server-circleci@latest"],
      "env": {
        "CIRCLECI_TOKEN": "$CIRCLECI_TOKEN"
      }
    }
  }
}
```

### Activation Script

Same defensive merge pattern as Claude module:
1. If `~/.gemini/settings.json` does not exist, create it with defaults
2. If it exists, use `jq` to merge `mcpServers` and settings while preserving user-added keys
3. If `jq` fails, do nothing (prevents data loss)
4. `chmod 600` on the file

### GEMINI.md

Read-only symlink via `home.file`. Contains:
- File hierarchy table pointing to `~/.ai/` files (3-rules.md, 2-coding-style.md, 1-profile.md, 4-preferences.yaml)
- Conflict resolution rules (higher priority wins)
- Compaction recovery checklist (re-read all `~/.ai/` files after context loss)
- Initialization instructions adapted for Gemini's capabilities

## Module 2: Codex CLI (`home/codex/default.nix`)

### Files Managed

| File | Method | Purpose |
|------|--------|---------|
| `~/.codex/config.toml` | Activation script (write-once) | Settings + MCP servers |
| `~/.codex/AGENTS.md` | Symlink (read-only) | Instruction file |

### Settings (`~/.codex/config.toml`)

```toml
model = "o3"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
model_reasoning_effort = "high"

[mcp_servers.qqq-mcp]
url = "http://localhost:8080/mcp"

[mcp_servers.circleci]
command = "npx -y @circleci/mcp-server-circleci@latest"
env = { CIRCLECI_TOKEN = "$CIRCLECI_TOKEN" }
```

### Activation Script

Unlike Claude/Gemini, Codex uses TOML (no `jq` equivalent for safe merging):
1. If `~/.codex/config.toml` does not exist or is empty, write full defaults
2. If it exists, leave it untouched (preserves user edits)
3. `chmod 600` on the file

This is write-once semantics. To pick up new Nix-managed defaults, user deletes the file and rebuilds.

### AGENTS.md

Read-only symlink via `home.file`. Same bootstrap structure as GEMINI.md, adapted for Codex. Codex falls back to `CLAUDE.md` if `AGENTS.md` is missing, but an explicit `AGENTS.md` gives us control over Codex-specific instructions.

## Module 3: Slack CLI (No config module needed)

Slack CLI is installed via Homebrew only. No Home Manager config module required -- it authenticates interactively via `slack login` and stores tokens in its own keychain. The Slack MCP for Claude is already connected via claude.ai cloud integration.

## Shared Context

All three AI tools reference the same `~/.ai/` files managed by `home/ai/default.nix`:

```
~/.ai/
  0-init.md           # Initialization instructions
  1-profile.md        # Personal profile (who James is)
  2-coding-style.md   # Engineering style guide
  3-rules.md          # Behavioral mandates
  4-preferences.yaml  # Machine-readable tuning knobs
  5-learnings.md      # Ongoing learnings
```

Each tool's instruction file (CLAUDE.md, GEMINI.md, AGENTS.md) serves as a bootstrap that tells the tool to load these shared files.

## Import Wiring

In `home/default.nix`, add to imports:

```nix
imports = [
  ./1password
  ./ai
  ./aws
  ./ca-certs
  ./claude
  ./codex      # NEW
  ./gemini     # NEW
  ./gpg
  # ... rest unchanged
];
```

## Files Changed Summary

| File | Change |
|------|--------|
| `modules/homebrew.nix` | Add `gemini-cli` to brews, `codex` and `slack-cli` to casks |
| `home/default.nix` | Add `./codex` and `./gemini` to imports |
| `home/gemini/default.nix` | NEW -- Gemini settings, MCP, GEMINI.md |
| `home/codex/default.nix` | NEW -- Codex settings, MCP, AGENTS.md |

## MCP Server Mapping

| Server | Claude (`~/.claude.json`) | Gemini (`~/.gemini/settings.json`) | Codex (`~/.codex/config.toml`) |
|--------|--------------------------|-----------------------------------|-------------------------------|
| qqq-mcp | `type: http, url` | `httpUrl` | `url` |
| CircleCI | `type: stdio, command/args` | `command/args` | `command` (single string) |
| GitHub | Plugin (cloud) | Not available | Not available |
| Atlassian | Plugin (cloud) | Not available | Not available |
| Slack | Cloud MCP (claude.ai) | Not available | Not available |
| SonarQube | Docker stdio | Could add later | Could add later |

GitHub, Atlassian, and Slack are Claude-specific integrations (plugins/cloud MCPs) and do not have equivalents for Gemini/Codex.

## Open Questions

None. All decisions resolved during brainstorming.
