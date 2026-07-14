# Shared "Global Development Context" bootstrap doc
# ==================================================
# Single source of truth for the agent-context bootstrap file that every AI
# tool gets: Claude (~/.claude/CLAUDE.md), Codex (~/.codex/AGENTS.md), and
# Gemini (~/.gemini/GEMINI.md). Previously this File-Hierarchy / Initialization
# / Compaction-Recovery block was inlined verbatim in three modules and had
# already drifted between them. Defined once here, parameterized only by the
# tool's own bootstrap filename, so the three can never diverge again.
#
#   selfRef  = how this file refers to ITSELF in the hierarchy table row 1
#              (Claude uses the full path; others just the bare filename)
#   selfName = the bare filename, used for the "Project <name>" rows
{
  mkAgentHierarchyDoc = { selfRef, selfName }: ''
    # Global Development Context

    ## File Hierarchy (load order)

    | Priority | File | Authority |
    |----------|------|-----------|
    | 1 | This file (`${selfRef}`) | Bootstrap, hierarchy, compaction recovery |
    | 2 | `~/.ai/3-rules.md` | Behavioral mandates (MUST/MUST NOT) — **binding** |
    | 3 | `~/.ai/2-coding-style.md` | Output formatting / code style — **normative** |
    | 4 | `~/.ai/1-profile.md` | Identity, role, environment — informational |
    | 5 | `~/.ai/4-preferences.yaml` | Machine-readable tuning knobs — advisory |
    | 6 | `~/.ai/5-learnings.md` | Operational notes / current ground truth — reference |
    | 7 | Project `${selfName}` (and project style/contributing files) | Per-repo overrides — scoped |

    **Conflict resolution:** Higher priority wins on the dimension it owns. Project-level files MAY override `3-rules.md` for repo-scoped settings (allowed commands, module structure, language conventions) but MUST NOT weaken safety rules.

    `~/.ai/0-init.md` is a launcher only — not part of the hierarchy.

    ## Initialization

    Load all six files in `~/.ai/` and treat them as system-level configuration.
    Use `3-rules.md` as strict constraints, `2-coding-style.md` as output formatting standards, `1-profile.md` as context, `4-preferences.yaml` as tunable parameters, and `5-learnings.md` as current operational ground truth.

    ## Second Brain (persistent memory vault)

    The Obsidian vault at `$SECOND_BRAIN_VAULT` is the durable cross-session,
    cross-machine memory. Its `index.md` is a short map — in Claude Code it is
    auto-injected at session start; in other tools, read it before substantive
    work. Pull specific vault notes on demand; do not bulk-load the vault.
    Before finishing substantive work (or on "save to second brain"), record
    durable outcomes using the `secondbrain-save` conventions: decisions →
    `decisions/` (ADR), project state → `projects/<project>.md` (append),
    reusable learnings → `knowledge/`, session log → `daily/YYYY-MM-DD.md`.
    Append/merge only; frontmatter `created`/`updated`/`tags`/`source`; link
    new notes from `index.md`. Never write secrets into the vault.

    ## Shared Tooling

    When Firecrawl MCP is available, prefer it for web search, scraping,
    crawling, mapping, structured extraction, and deep research. Verify
    consequential claims against primary sources and follow the active
    repository's rules for external access and sensitive data.

    ## Compaction Recovery (NON-NEGOTIABLE)

    After context compaction, the agent MUST re-read ALL `~/.ai/` files before continuing work. Compaction discards these files from context. Read them in this order:
    1. `~/.ai/3-rules.md`
    2. `~/.ai/2-coding-style.md`
    3. `~/.ai/1-profile.md`
    4. `~/.ai/4-preferences.yaml`
    5. `~/.ai/5-learnings.md`
    6. Active project `${selfName}` (and any project-local style/contributing files)
    7. `./docs/SESSION-STATE.md` and `./docs/TODO.md` (if they exist)
  '';
}
