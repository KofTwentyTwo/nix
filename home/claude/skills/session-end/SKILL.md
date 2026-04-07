---
name: session-end
description: "Save session state and wrap up a work session cleanly. Use when the user says 'wrap up', 'end session', 'save state', 'shutdown', 'stopping for now', or indicates they are done working."
---

# Session End

Persist session state so the next session can resume seamlessly.

## Trigger

Activate when the user says any of:
- "wrap up" / "wrapping up"
- "end session" / "shutdown"
- "save state" / "save progress"
- "stopping for now" / "done for today"
- "let's call it"

## Sequence

### 1. Update Session State

Write or update `docs/SESSION-STATE.md` in the current repo with:

```markdown
# Session State

**Last Updated:** {today's date}

## Current Status
{one-line summary of where things stand}

## What Was Done This Session
{bulleted list of concrete accomplishments}

## Active Branches
| Branch | Status |
|--------|--------|
{list active branches and their state}

## Pending Work
{bulleted checklist of remaining items}

## Key Reference
{any IDs, URLs, values the next session will need}
```

### 2. Update TODO

Update `docs/TODO.md` if tasks were completed or new ones discovered:
- Mark completed items with `[x]`
- Add new items discovered during the session
- Keep the file organized by priority/epic

### 3. Capture Learnings (only if applicable)

If genuinely new learnings were discovered this session (debugging gotchas, framework quirks, API behaviors, tooling issues), add them to `~/.ai/5-learnings.md`.

Only add learnings that are:
- Non-obvious and would save time in the future
- Not already documented elsewhere
- Applicable beyond this one session

Do NOT add routine observations or restate what's in the code.

### 4. Check for Uncommitted Work

Run `git status` and report:
- Uncommitted changes that should be committed
- Untracked files that might need attention
- Do NOT commit automatically -- ask first

### 5. Final Summary

Output:

```
## Session Complete

### Accomplished
{bulleted list}

### Where we left off
{exact state, branch, what's in progress}

### Next session
{what to work on next, any blockers}
```

## Rules

- Always write session state to the REPO (at `docs/`), never to external locations
- Keep SESSION-STATE.md under 100 lines -- it's a resume point, not a journal
- Keep TODO.md organized -- don't let it grow unbounded, archive completed sections periodically
- Do NOT push without asking
- Do NOT commit without asking
- The learnings file (`~/.ai/5-learnings.md`) is managed by Nix/Home Manager -- propose changes, let the user decide whether to update the Nix source
