# Design: Pi as Primary Coding Agent

**Date:** 2026-05-20
**Status:** Draft
**Approach:** Vanilla pi, fully nix-managed, hand-crafted extensions grown organically (no oh-my-pi, no MCP adapter, 1Password shell-command auth)

## Goal

Install pi (Mario Zechner's minimal terminal coding harness, `@earendil-works/pi-coding-agent`) as the daily-driver coding agent, with intelligent model switching across local Ollama (MLX backend) and cloud providers via subscription/1Password auth. Pi coexists with Claude Code (specialized for its skills ecosystem) and Codex (specialized for OpenAI's harness); pi takes the primary slot.

Setup is fully nix-managed. Extensions are NOT pre-installed — they grow organically as actual workflow pain surfaces, written by pi itself in the "first-hour ritual" and captured back into the flake.

## Approach Rationale

Three decisions shape this design:

1. **Vanilla pi, build everything yourself** — no oh-my-pi base, no pre-built extension marketplace. Pi's value compounds when you teach it to extend itself; pre-installed extensions defeat the philosophy.
2. **No MCP adapter** — wrap each existing MCP server (github, qqq-mcp, circleci-mcp, atlassian, ruflo) as a custom pi tool when needed. Cleaner caching/error handling, no `pi-mcp-adapter` dependency.
3. **1Password shell-command auth** — `apiKey: "!op read op://..."` in models.json. Pi calls `op` at request time. Keys never on disk, never in nix store, rotated by changing 1Password.

## Architecture

```
pi (primary CLI)  ←  Claude Code (specialized)  ←  Codex (specialized)
 │
 ├── ~/.pi/agent/models.json   (nix-rendered)
 │    ├── ollama     → localhost:11434  (MLX backend, requires 32GB+ unified memory)
 │    ├── anthropic  → subscription auth (reuses Claude Code session)
 │    ├── openai     → subscription auth (reuses Codex session)
 │    └── google     → subscription auth (Gemini CLI)
 │    # Groq deferred — add when 1Password item exists (Phase 2)
 │
 ├── ~/.pi/agent/SYSTEM.md     (~50 lines, pi-specific behaviors)
 ├── ~/.pi/agent/AGENTS.md     (~20 lines, pointer to ~/.ai/*.md chain)
 ├── ~/.pi/agent/skills/       (empty in Phase 1 — add only when needed)
 ├── ~/.pi/agent/extensions/   (empty in Phase 1 — first is the one pi writes for itself)
 └── ~/.pi/agent/settings.json (theme, hotkeys — minimal)
```

## Installation

| Component | Method | Status |
|-----------|--------|--------|
| Pi CLI | npm-global as `@mariozechner/pi-coding-agent` | **Already in `home/npm-globals/default.nix:32`** |
| Ollama | Homebrew cask `ollama-app` (provides `ollama` CLI + GUI) | **Already in `modules/homebrew.nix:252`** — MLX backend auto-enabled on 32GB+ Apple Silicon |
| Local models | Activation script in new `home/pi/default.nix` | NEW — `ollama pull` if missing |

Local models pulled idempotently:

| Model | Slot | Approx size |
|-------|------|-------------|
| `qwen3-coder:30b` | Local 30B-class | ~17 GB (Ollama-default Q4_K_M) |
| `qwen2.5-coder:7b` | Fast lane | ~5 GB |
| `llama3.3:70b-instruct-q4_K_M` | Heavy local reasoning | ~42 GB |

Total local download: ~64 GB one-time.

**Tag note:** Ollama uses Modelfile-based tags, not raw GGUF filenames. The default `:30b` tag resolves to a sensible quant chosen by the publisher (currently Q4_K_M). If you want a specific quant later, look up actual published tags via `ollama show qwen3-coder` rather than guessing from HF-style names.

## Module Structure

```
home/pi/
├── default.nix     # imports, home.file declarations, activation script
├── SYSTEM.md       # pi-specific behaviors (verbatim copy via home.file)
├── AGENTS.md       # pointer to ~/.ai/*.md chain (verbatim copy via home.file)
└── models.nix      # nix function returning models.json data
```

Plus one minimal edit:

| File | Change |
|------|--------|
| `home/default.nix` | Import `./pi` (line ~38, alphabetically between `./opencode` and `./procs`) |

**Already in place** (no changes needed):
- `home/npm-globals/default.nix` — `@mariozechner/pi-coding-agent` package
- `modules/homebrew.nix` — `ollama-app` cask

**No sops changes.** All API keys resolved at request-time via `op` CLI. Subscription-auth providers need nothing.

## File Contents

### `home/pi/default.nix`

```nix
{ config, pkgs, lib, ... }:
let
  modelsData = import ./models.nix { inherit config lib; };
in
{
  home.file = {
    ".pi/agent/SYSTEM.md".source = ./SYSTEM.md;
    ".pi/agent/AGENTS.md".source = ./AGENTS.md;
    ".pi/agent/models.json".text = builtins.toJSON modelsData;
  };

  # Idempotent: pull Ollama models if missing. Runs on every `switch`,
  # but `ollama list | grep` short-circuits if model already present.
  home.activation.pullPiModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v ollama >/dev/null 2>&1; then
      for m in qwen3-coder:30b qwen2.5-coder:7b llama3.3:70b-instruct-q4_K_M; do
        if ! ollama list 2>/dev/null | grep -q "''${m}"; then
          $DRY_RUN_CMD ollama pull "''${m}" || true
        fi
      done
    fi
  '';
}
```

### `home/pi/models.nix`

```nix
{ config, lib }:
{
  providers = {
    ollama = {
      baseUrl = "http://localhost:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";
      models = [
        { id = "qwen3-coder:30b";              name = "Qwen3 Coder 30B (local)";   contextWindow = 256000; }
        { id = "qwen2.5-coder:7b";             name = "Qwen2.5 Coder 7B (fast)";   contextWindow = 128000; }
        { id = "llama3.3:70b-instruct-q4_K_M"; name = "Llama 3.3 70B (reasoning)"; }
      ];
    };
    anthropic = {
      api = "anthropic-messages";
      # Subscription auth — first /model selection opens browser OAuth, reuses Claude Code session.
      models = [
        { id = "claude-opus-4-7";   name = "Claude Opus 4.7"; }
        { id = "claude-sonnet-4-6"; name = "Claude Sonnet 4.6"; }
      ];
    };
    openai = {
      api = "openai-responses";
      models = [ { id = "gpt-5"; name = "GPT-5"; } ];
    };
    google = {
      api = "google-generative-ai";
      models = [ { id = "gemini-2.5-pro"; name = "Gemini 2.5 Pro"; } ];
    };
    # groq: deferred — add when op://Personal/groq-api-key/credential exists in 1Password
  };
}
```

**Schema caveat:** the exact subscription-auth syntax (no `apiKey` field? explicit `auth: "oauth"`? `subscription: true`?) may differ from pi's current schema. On first bootstrap, run `pi /model`; if a subscription provider fails to authenticate, consult [pi's models.md](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md) and adjust `models.nix`. Worst-case fallback: use `!op read op://Personal/<provider>-api-key/credential` for all four cloud providers.

### `home/pi/SYSTEM.md`

Short, pi-specific. Does NOT duplicate `~/.ai/3-rules.md`. Topics:

- **Default model: `claude-opus-4-7`** (subscription auth — your existing Claude Pro/Max). Strongest available agentic model; local models are on-demand via `/model` or per-project overlays.
- Per-project override: place `.pi/SYSTEM.md` in any repo to switch the default (e.g., to a local model for sensitive code), or `.pi/models.json` to strip cloud providers entirely.
- Tree-session convention: "use `/fork` when exploring a hypothesis or side-quest; preserve the main session for the through-line"
- Prompt templates location: `~/.pi/agent/templates/` (for `/name` expansion)
- Pointer: "binding behavioral rules are in `~/.ai/3-rules.md`, loaded via `AGENTS.md`"

### `home/pi/AGENTS.md`

```markdown
# Agent rules — read first

Authoritative behavior rules:
- ~/.ai/3-rules.md       MUST / MUST NOT mandates (binding)
- ~/.ai/2-coding-style.md  Output formatting (normative)
- ~/.ai/1-profile.md       Identity, role, environment
- ~/.ai/4-preferences.yaml Machine-readable tuning knobs
- ~/.ai/5-learnings.md     Current operational ground truth

Project rules: ./CLAUDE.md (also serves Codex via AGENTS.md mirror).
Pi-specific conventions: ~/.pi/agent/SYSTEM.md.
```

## AGENTS.md / `~/.ai/` Discovery

Pi walks parent directories from cwd up to `$HOME` looking for `AGENTS.md` and `CLAUDE.md`. Since `~/.ai/*.md` files are NOT named `AGENTS.md`, pi will not auto-discover them via parent-walk — they're referenced by the `~/.pi/agent/AGENTS.md` pointer.

**Bootstrap verification step:** `pi -p "what rules am I operating under?"` — confirm the response cites content from `~/.ai/3-rules.md`. If it doesn't, the pointer pattern failed and `home/pi/AGENTS.md` needs to inline the rules verbatim instead of pointing at them.

## Bootstrap Sequence

1. `sudo darwin-rebuild switch --flake ~/.config/nix`
2. Activation pulls Ollama models (~70 GB one-time; skips existing)
3. `pi /model` → select **`claude-opus-4-7`** first. This triggers browser OAuth against your existing Claude Pro/Max session. **Critical**: if this fails, the default model is unreachable — adjust `models.nix` per the schema caveat above before continuing.
4. Repeat for openai/google subscription rows (less critical — these are on-demand fallbacks)
5. `pi -p "list the files in this dir"` — print-mode smoke test
6. **First-hour ritual:** open pi interactively and prompt:

   > Write me a TypeScript extension at `~/.pi/agent/extensions/safe-bash.ts` that hooks `tool_call` and pauses for confirmation before executing: `terraform apply`, `kubectl delete`, `aws … rm`, `helm uninstall`, `git push --force`. After implementing, hot-reload and test against a dry-run command.

   Let pi build, reload, test. Once it works, capture the resulting `.ts` file back into the flake (see Capture-Back Discipline below).

## Capture-Back Discipline

Extensions and skills created at runtime in `~/.pi/agent/extensions/` and `~/.pi/agent/skills/` are unmanaged user state. To preserve them across machines and rebuilds:

1. Move the file from `~/.pi/agent/extensions/foo.ts` to `home/pi/extensions/foo.ts`
2. Add to `home/pi/default.nix`:
   ```nix
   home.file.".pi/agent/extensions/foo.ts".source = ./extensions/foo.ts;
   ```
3. `git add` and commit. Subsequent rebuilds replicate the extension.

The runtime → flake transition is deliberate: keep the experimentation surface fast (mutate `~/.pi/agent/extensions/` directly during iteration), commit only when an extension proves itself.

## Phase 2 Backlog

Extensions to hand-craft (with pi's help) when actual pain surfaces. Not in Phase 1 scope. Order is likely chronological need, not priority.

| Extension | Trigger to build |
|-----------|------------------|
| `safe-bash.ts` | First time pi proposes a destructive command (likely day 1 — the ritual) |
| `kctx.ts` (kubeconfig scoping via `createBashTool` factory) | First wrong-cluster scare or `kubectl` context confusion |
| `incident.ts` (tree-based investigation mode) | Next on-call shift |
| `tf-plan.ts` (structured terraform plan JSON as a tool) | Next non-trivial terraform review |
| `circleci-triage.ts` (custom tool wrapping CircleCI API) | Next pipeline failure |
| `qqq-debug.ts` (QQQ-specific tooling) | Next QQQ issue |
| Hashline-style edit anchors | First multi-edit refactor pi botches |
| LSP integration | First refactor where symbol-graph awareness matters |

## Verification Checklist

After `darwin-rebuild switch`:

- [ ] `pi --version` returns a version
- [ ] `ollama list` shows the three pulled models
- [ ] `pi -p "list the files in this dir"` returns a sensible response (print mode works)
- [ ] `pi /model` shows four providers (ollama, anthropic, openai, google)
- [ ] **`claude-opus-4-7` (the default) authenticates via OAuth on first selection** — if not, fix before proceeding (default is unreachable otherwise)
- [ ] `pi /session` after a few turns shows tree-shaped JSONL in `~/.pi/agent/sessions/`
- [ ] `pi -p "what rules am I operating under?"` cites `~/.ai/3-rules.md` content
- [ ] `pi --mode rpc` accepts a JSONL request and responds (proves the headless automation path for Phase 2)

## Out of Scope (Phase 1)

Explicitly NOT included:

- **MCP adapter** — wrap MCP servers as custom pi tools only when actually needed
- **oh-my-pi base** — keep pi vanilla; cherry-pick patterns into hand-written extensions if/when they prove themselves
- **Pre-symlinked Claude skills** — empty `skills/` dir; port only ones that prove themselves
- **Plan-mode port** — pi rejects plan mode by design; honor that
- **Sops-injected API keys** — `!op read` is the chosen pattern
- **Auto-routing extension** — defer until manual `Ctrl+P` model-cycling actually annoys you
- **Replacing Claude Code or Codex** — they stay; pi is additive

## Related Files

- `home/ai/3-rules.md` — Authoritative behavior rules referenced by pi's AGENTS.md
- `home/ai/2-coding-style.md` — Output formatting conventions
- `home/claude/default.nix` — Claude Code module (untouched; coexists)
- `home/codex/default.nix` — Codex CLI module (existing AGENTS.md already serves pi too)
- `~/.config/nix/CLAUDE.md` — Project rules pi discovers via parent-walk
