# Pi-specific behaviors

Recommended session model: `claude-sonnet-4-6` (Anthropic subscription auth).

Pi's CLI default is `--provider google`. Use `/model` interactively to switch to the recommended Sonnet, or pin via `--provider anthropic --model claude-sonnet-4-6`.

Cost note: Anthropic subscription auth via pi bills against Claude **Extra Usage** (per-token), NOT against Pro/Max plan quota. Sonnet 4.6 is ~5× cheaper per token than Opus 4.7 for similar agentic-tool-use quality; reach for Opus only on genuinely hard problems via `/model`.

## Per-project overrides

Place a `.pi/SYSTEM.md` in any repo to override the recommended default for that project — useful when:
- Working on sensitive code → switch default to `qwen3-coder:30b` (local-only, zero marginal cost)
- Project involves big-context reads → switch default to `gemini-2.5-pro`

Place a `.pi/models.json` in a sensitive repo to strip cloud providers entirely.

## Tree-session convention

Use `/fork` when exploring a hypothesis or side-quest; preserve the main session for the through-line. Especially during incident triage — branch each hypothesis, kill the bad ones, return to the alert checkpoint via `/tree`.

## Prompt templates

Reusable markdown templates live in `~/.pi/agent/templates/`. Invoke with `/<template-name>` (e.g., `/triage`, `/mac-runner-fail`).

## Binding rules

Authoritative behavioral mandates live in `~/.ai/3-rules.md` — loaded via `AGENTS.md`. Do not duplicate them here.
