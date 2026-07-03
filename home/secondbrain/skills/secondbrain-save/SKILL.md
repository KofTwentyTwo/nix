---
name: secondbrain-save
description: Save durable outcomes of the current session into the Obsidian second-brain vault ($SECOND_BRAIN_VAULT). Use at the end of substantive work, when the user says "save to second brain" / "remember this", or after making a decision worth keeping. Records decisions as ADRs, project state, reusable learnings, and a daily log entry.
---

# Save to Second Brain

Persist the durable outcomes of this session into the vault at
`$SECOND_BRAIN_VAULT` (fallback: the path named in the global CLAUDE.md).
Everything is plain Markdown with wikilinks, browsable in Obsidian.

## What goes where

| Outcome | Destination | Form |
|---|---|---|
| Durable technical/architectural decision | `decisions/ADR-NNNN-<slug>.md` | ADR: Context, Decision, Consequences |
| Project state change, open threads | `projects/<project>.md` | Append/update sections; keep newest state at top of "Current state" |
| Reusable learning, gotcha, how-to, command | `knowledge/<slug>.md` | Short, self-contained note |
| Session summary | `daily/YYYY-MM-DD.md` | Bullet(s): what was done + wikilinks to the notes above |

`<project>` = the repo/project name (git remote basename, e.g. `nix`).

## Rules (binding)

1. **Append/merge only.** Never rewrite an existing note wholesale; add or
   update the relevant section. When updating, bump `updated:` in frontmatter.
2. **Frontmatter on every note**:
   ```yaml
   ---
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [decision|project|knowledge|daily, ...topic tags]
   source: claude-session
   ---
   ```
3. **No orphans.** Link every new note from `index.md` (Recent decisions /
   Active projects) or from a relevant hub note, using `[[wikilinks]]`.
4. **ADR numbering**: next free `NNNN` in `decisions/` (zero-padded).
5. **Keep `index.md` a map, not content** — one line per link, trim stale ones.
6. **Never write secrets** (tokens, keys, passwords) into the vault.
7. Don't record trivia: only outcomes that change future behavior or would
   otherwise be re-derived at cost.

## Procedure

1. Identify durable outcomes: decisions made, state changes, learnings.
   If there are none, say so and write only the daily-log bullet.
2. Write/update the notes per the table above.
3. Add today's `daily/YYYY-MM-DD.md` entry (create with frontmatter if absent)
   summarizing the session in 1–3 bullets with links.
4. Update `index.md` links if new notes were created.
5. If the vault is a git repo: `git add -A && git commit -m "save: <short summary>"`
   (push is handled by the consolidation job; pushing here is optional).
