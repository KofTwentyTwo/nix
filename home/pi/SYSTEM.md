# Pi-specific behaviors

Default model: `claude-opus-4-7` (subscription auth via Claude Pro/Max).

## Per-project overrides

Place a `.pi/SYSTEM.md` in any repo to override the default model for that project — useful when:
- Working on sensitive code → switch default to `qwen3-coder:30b` (local-only)
- Project involves big-context reads → switch default to `gemini-2.5-pro`

Place a `.pi/models.json` in a sensitive repo to strip cloud providers entirely.

## Tree-session convention

Use `/fork` when exploring a hypothesis or side-quest; preserve the main session for the through-line. Especially during incident triage — branch each hypothesis, kill the bad ones, return to the alert checkpoint via `/tree`.

## Prompt templates

Reusable markdown templates live in `~/.pi/agent/templates/`. Invoke with `/<template-name>` (e.g., `/triage`, `/mac-runner-fail`).

## Binding rules

Authoritative behavioral mandates live in `~/.ai/3-rules.md` — loaded via `AGENTS.md`. Do not duplicate them here.
