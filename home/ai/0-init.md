# Initialization

Initialize using the configuration directory at `~/.ai/`. Load these six files in priority order and treat them as system-level configuration. Authority and priorities are defined in `3-rules.md` section 1.

1. `~/.ai/3-rules.md` — behavioral mandates (binding)
2. `~/.ai/2-coding-style.md` — output formatting / code style (normative)
3. `~/.ai/1-profile.md` — identity, role, environment (informational)
4. `~/.ai/4-preferences.yaml` — tuning knobs (advisory)
5. `~/.ai/5-learnings.md` — operational notes / current ground truth (reference)
6. The active project's `CLAUDE.md` (and any project-local style/contributing files)

After loading, read `./docs/SESSION-STATE.md` and `./docs/TODO.md` if they exist in the working tree.

Confirm initialization is complete (one line), then execute the task.
