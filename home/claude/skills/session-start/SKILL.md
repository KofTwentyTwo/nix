---
name: session-start
description: "Resume work from a previous session. Use when the user says 'continue from last session', 'resume', 'pick up where we left off', or starts a new work session in a repo. Reads session state, TODOs, and project context to establish continuity."
---

# Session Start

Establish continuity when beginning or resuming a work session.

## Trigger

Activate when the user says any of:
- "continue from last session"
- "resume"
- "pick up where we left off"
- "what were we working on?"
- Or at the start of any work session in a repo

## Sequence

### 1. Identify Context

Determine the current repo from cwd. Note the git remote, current branch, and any uncommitted changes.

### 2. Load Project Instructions

Read in order (skip any that don't exist):
1. `~/.ai/3-rules.md` (behavioral mandates)
2. `~/.ai/1-profile.md` (user profile)
3. `~/.ai/2-coding-style.md` (coding conventions)
4. `~/.ai/4-preferences.yaml` (tuning knobs)
5. Repo `CLAUDE.md` (project-specific context)

### 3. Load Session State

Check for and read these files (in the repo, not external):
- `docs/SESSION-STATE.md` -- last session's context, decisions, blockers
- `docs/TODO.md` -- active tasks and backlog
- `docs/PLAN-*.md` -- any active plans

### 4. Detect Issue Tracker

Determine the tracker from the git remote:
| Remote org | Tracker | Tool |
|-----------|---------|------|
| `Dallasm*` / `DMD*` / `dmdbrands` | Jira | MCP Atlassian |
| `QRun-IO` / `KofTwentyTwo` | GitHub Issues | MCP GitHub / `gh` CLI |
| Unknown | Ask user | -- |

### 5. Check Branch State

- Verify you're on a feature branch (not `main` or `develop`)
- If on `main`/`develop`, ask: "Should I create a feature branch?"
- Show `git status` summary (uncommitted changes, ahead/behind)

### 6. Present Summary

Output a concise summary:

```
## Session Resume

**Repo:** {name} ({branch})
**Last session:** {date from SESSION-STATE.md}
**Status:** {one-line summary}

### Where we left off
{key context from SESSION-STATE.md}

### Active work
{from TODO.md -- in-progress items only}

### Next steps
{from TODO.md or SESSION-STATE.md pending items}
```

## Rules

- Do NOT create files during startup -- only read
- Do NOT start working until the user confirms direction
- If no session state exists, say so and ask what the user wants to work on
- Keep the summary concise -- 1-2 paragraphs max, not a wall of text
