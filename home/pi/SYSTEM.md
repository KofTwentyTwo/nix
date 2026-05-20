# Pi-specific behaviors

Default model: `gemini-3.5-flash` (Google provider — nix-enforced in `~/.pi/agent/settings.json` via `home/pi/default.nix`).

Switch via `/model` when:
- Gemini plateaus on a hard problem → `claude-sonnet-4-6` (Anthropic subscription).
- Genuinely difficult reasoning → `claude-opus-4-7`.
- Sensitive code → `qwen3-coder:30b` (local Ollama, zero marginal cost).

Cost gotcha: Anthropic subscription auth via pi bills against Claude **Extra Usage** (per-token), NOT Pro/Max plan quota. Sonnet 4.6 is ~5× cheaper per token than Opus 4.7 at similar agentic quality — reach for Opus only on truly hard problems.

## Per-project overrides

Place a `.pi/SYSTEM.md` in any repo to override the default for that project. Place a `.pi/models.json` in a sensitive repo to strip cloud providers entirely.

## Tree-session convention

Use `/fork` when exploring a hypothesis or side-quest; preserve the main session for the through-line. Especially during incident triage — branch each hypothesis, kill the bad ones, return to the alert checkpoint via `/tree`.

## Prompt templates

Reusable markdown templates live in `~/.pi/agent/templates/` (nix-managed via `home/pi/templates/`). Invoke with `/<template-name>`. Current set:
- `/triage` — incident / unexpected-failure diagnosis
- `/mac-runner-fail` — CircleCI Mac runner debugging

## Binding rules

Authoritative behavioral mandates live in `~/.ai/3-rules.md` — loaded via `AGENTS.md`. Do not duplicate them here.
