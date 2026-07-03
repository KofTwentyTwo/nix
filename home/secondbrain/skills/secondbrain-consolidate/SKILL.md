---
name: secondbrain-consolidate
description: Tidy the Obsidian second-brain vault ($SECOND_BRAIN_VAULT) - merge duplicate notes, fix stale facts and dead wikilinks, and regenerate index.md as a concise map. Run by the weekly scheduled job (headless) or on demand ("consolidate the second brain"). Idempotent - a clean vault results in zero changes.
---

# Consolidate the Second Brain

Maintenance pass over the vault (cwd or `$SECOND_BRAIN_VAULT`). Goal: keep the
vault accurate, deduplicated, and navigable. **Idempotent** — if nothing needs
fixing, change nothing (the scheduler runs this repeatedly).

## Procedure

1. **Survey**: read `index.md`, list files in `daily/`, `projects/`,
   `decisions/`, `knowledge/`, `people/`.
2. **Dedupe knowledge/**: merge near-duplicate notes into the better one
   (union of content, earliest `created`, today's `updated`); delete the
   loser only after its content and inbound links are migrated.
3. **Fix staleness**: in `projects/*.md`, collapse superseded "Current state"
   bullets into a brief history line or drop them; resolve contradictions in
   favor of the newest dated statement.
4. **Repair links**: find `[[wikilinks]]` pointing at missing notes — fix the
   target, or remove the link if the note is truly gone.
5. **Regenerate `index.md`**: every section listed, every active project and
   recent (≤10) decision linked, nothing orphaned, no dead links, still short.
   Bump `updated:`.
6. **Daily logs**: leave content untouched (they are history), but you may
   fix broken links inside them.
7. Preserve all frontmatter conventions (see the secondbrain-save skill).
   Never write secrets. Never delete `decisions/` content — ADRs are permanent
   (mark superseded ADRs with `status: superseded by [[...]]` instead).

The scheduled wrapper handles `git commit`/`push` after this skill runs; when
invoked interactively, offer to commit at the end.
