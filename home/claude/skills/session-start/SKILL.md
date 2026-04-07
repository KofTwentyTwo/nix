---
name: session-start
description: "Resume work from a previous session. Use when the user says 'continue from last session', 'resume', 'pick up where we left off', or starts a new work session in a repo. Reads session state, TODOs, and project context to establish continuity. Also handles one-time migration of Claude state from the legacy ClaudeCode sidecar repo."
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

### 2. Legacy Migration Check (one-time per repo)

Check if this repo still has its Claude state in the legacy ClaudeCode sidecar repo. This migration only needs to happen once per repo -- if state files already exist in the repo, skip this step entirely.

**Detection:** Check if `docs/SESSION-STATE.md` exists in the current repo. If it does NOT, check for a matching directory in the ClaudeCode sidecar:

```
SIDECAR="/Users/james.maes/Git.Local/kof22/ClaudeCode"
REPO_NAME=$(basename $(pwd))
```

Look for `$SIDECAR/$REPO_NAME/`. If it exists, perform the migration:

#### 2a. Import state files from sidecar

Copy files from the sidecar into the repo. Common patterns:

| Sidecar location | Repo destination |
|-----------------|-----------------|
| `SESSION-STATE.md` or `SESSION_STATE.md` | `docs/SESSION-STATE.md` |
| `TODO.md` | `docs/TODO.md` |
| `CLAUDE.md` or `CLAUDE-root.md` | Merge into repo root `CLAUDE.md` |
| `.claude/CLAUDE.md` | Merge into repo root `CLAUDE.md` |
| `.claude/SESSION.md` | Merge into `docs/SESSION-STATE.md` |
| `.claude/settings.local.json` | `.claude/settings.local.json` (if not already present) |
| `docs/PLAN-*.md` | `docs/plans/PLAN-*.md` |
| `docs/LEARNINGS.md` | `docs/LEARNINGS.md` |
| `docs/*.md` (other) | `docs/reference/` |
| `specs/*.md` | `docs/plans/` |
| Other `*.md` files | `docs/reference/` |

Create target directories as needed (`docs/`, `docs/plans/`, `docs/reference/`).

#### 2b. Update .gitignore

Check the repo's `.gitignore` for legacy entries that block Claude state files. Remove or replace entries like:

```
# OLD (remove these)
.claude/settings.local.json
.claude/SESSION.md
.claude/CLAUDE.md
docs/SESSION-STATE.md
docs/TODO.md
```

Replace with:

```
# Claude Code (keep settings.local.json out -- machine-specific permissions)
.claude/settings.local.json
```

This allows `docs/SESSION-STATE.md`, `docs/TODO.md`, and `.claude/skills/` to be tracked in git.

#### 2c. Create or update CLAUDE.md

If the repo has no `CLAUDE.md`, create one using the sidecar's version as a base. If both exist, merge them -- the sidecar version often has more detail accumulated over sessions.

The CLAUDE.md should include at minimum:
- Project name and description
- Key commands (build, test, run)
- Jira project key (if applicable) with transition IDs
- Session continuity section pointing to `docs/SESSION-STATE.md` and `docs/TODO.md`

#### 2d. Report the migration

Tell the user what was migrated. Ask them to review and commit:

```
Migrated Claude state from ClaudeCode sidecar for {repo-name}:
- {list of files imported}
- Updated .gitignore to allow Claude state files
- {created/updated} CLAUDE.md

Please review and commit when ready.
```

Do NOT auto-commit the migration. The user should review first.

### 3. Load Project Instructions

Read in order (skip any that don't exist):
1. `~/.ai/3-rules.md` (behavioral mandates)
2. `~/.ai/1-profile.md` (user profile)
3. `~/.ai/2-coding-style.md` (coding conventions)
4. `~/.ai/4-preferences.yaml` (tuning knobs)
5. Repo `CLAUDE.md` (project-specific context)

### 4. Load Session State

Check for and read these files (in the repo):
- `docs/SESSION-STATE.md` -- last session's context, decisions, blockers
- `docs/TODO.md` -- active tasks and backlog
- `docs/PLAN-*.md` -- any active plans

### 5. Detect Issue Tracker

Determine the tracker from the git remote:
| Remote org | Tracker | Tool |
|-----------|---------|------|
| `Dallasm*` / `DMD*` / `dmdbrands` | Jira | MCP Atlassian |
| `QRun-IO` / `KofTwentyTwo` / `qrun` | GitHub Issues | MCP GitHub / `gh` CLI |
| Unknown | Ask user | -- |

### 6. Check Branch State

- Verify you're on a feature branch (not `main` or `develop`)
- If on `main`/`develop`, ask: "Should I create a feature branch?"
- Show `git status` summary (uncommitted changes, ahead/behind)

### 7. Present Summary

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

- Do NOT start working until the user confirms direction
- If no session state exists (and no sidecar state to migrate), say so and ask what the user wants to work on
- Keep the summary concise -- 1-2 paragraphs max, not a wall of text
- Migration is a one-time operation per repo -- once files are in the repo, the sidecar is ignored
- When merging CLAUDE.md files, prefer the more detailed/recent version
- Never delete files from the ClaudeCode sidecar -- only copy from it. The user can archive it when all repos are migrated.
