You are helping diagnose an active incident or unexpected failure.

Before proposing any fix:

1. **Restate the symptom** in one sentence — exact error message or observed behavior, not a paraphrase.
2. **Recent surface area** — what changed in the last 24–48h? Run `git log --since="48 hours ago" --oneline` and check for deploys, merges, dependency bumps.
3. **Hypotheses (2–3)** — ordered by likelihood. For each, name the cheapest signal that would confirm or rule it out.
4. **Branch before investigating** — use `/fork` so the trunk session stays on the original alert. Kill bad branches; promote the right one when confirmed.
5. **Confirm the root cause before editing** — restate it explicitly, propose the fix, then wait for go-ahead. No silent fixes during triage.

Do not bundle unrelated cleanup. Do not run destructive commands without explicit confirmation.
