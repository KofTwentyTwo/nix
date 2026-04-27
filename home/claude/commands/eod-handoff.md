---
description: "End-of-day handoff: writes (or updates) ./docs/SESSION-STATE.md and ./docs/HANDOFF.md so tomorrow's session boots from solid ground. Captures what was done, what's open, what's blocked, and any context that wouldn't be obvious from git history."
argument-hint: "[--quick] [--push]"
---

# /eod-handoff

Snapshot today's state into a form that tomorrow-you (or any other Claude session) can pick up cleanly. Updates the existing session-continuity files; creates a handoff note if the day's work warrants one.

## When to use

- End of the day, before stepping away.
- Before a long break (vacation, weekend, etc.) — use `--push` so the state lives on the remote.
- Before switching to a different repo for a while.
- Before paging another engineer onto the work.

## Sequence

### 1. Gather signals from the working tree

In parallel:

```bash
git status --porcelain                                  # uncommitted changes
git log --oneline --since="08:00" --author="$(git config user.email)"  # today's commits
git diff --stat HEAD~$(git rev-list --since="08:00" --count HEAD)..HEAD 2>/dev/null  # net change
gh pr list --author "@me" --state open --json number,title,statusCheckRollup,reviewDecision
gh pr view --json number,title,reviewDecision,statusCheckRollup 2>/dev/null  # current branch's PR
cat ./docs/SESSION-STATE.md ./docs/TODO.md 2>/dev/null  # last session
```

Read recent commits, modified files, and any in-progress diff. Note:
- Was the day's work committed cleanly, or are there WIP changes?
- Are there open PRs the user authored that shifted state today?
- Any tests added but not run, or known to be failing?

### 2. Update `./docs/SESSION-STATE.md`

Always update (don't replace) — this is the rolling session-continuity file.

Structure (keep concise; this file is loaded into context every session):

```markdown
# Session State

**Last updated:** <date>

## Current status
<one paragraph: where we are in the active work>

## Active branch
- `<branch>` — <one line: what it's for>
- PR: #<number> <title> — <status>

## What was done this session
- <bullet>
- <bullet>

## What's open
- <bullet>
- <bullet>

## What's blocked
- <bullet (with the blocker)>

## Key decisions
<anything decided today that the next session needs to know — architectural calls, ticket scope changes, agreed-upon trade-offs>
```

If `./docs/SESSION-STATE.md` doesn't exist, create it. If `./docs/` doesn't exist, create it.

### 3. Update `./docs/TODO.md`

Move completed items from "Active" to "Recently Completed" with today's date. Add new items surfaced today. Don't reorder unless the priority obviously changed.

### 4. Decide whether to write `./docs/HANDOFF.md`

Write a handoff note if ANY of:
- The day's work is ending mid-task in a way that's not obvious from git
- Another engineer (or future-you-on-vacation-return) needs to pick this up cold
- There's debugging context (what was tried, what didn't work) that would be lost
- A decision was deferred and the next session should know what's pending
- Tests are in a known-broken state that's expected (don't surprise tomorrow-you)

Otherwise skip — `SESSION-STATE.md` carries enough context for the standard continue-tomorrow case.

`HANDOFF.md` structure (when written):

```markdown
# Handoff — <date>

## Goal
<the active goal in one sentence>

## Where I left off
<one paragraph; specific enough that someone could resume>

## What's working
<bullets — completed and verified>

## What's not working / partial
<bullets — be specific. file:line where applicable>

## What I tried that didn't work
<short list with one-sentence "why it didn't work" each>

## What to try next
<ordered list of next-step options, with rationale>

## Open questions
<for the user, the team, or external — be explicit about who should answer>

## Files of interest
- `path/to/file:line` — <why>
- `path/to/file:line` — <why>

## How to reproduce the current state
$ <command>
$ <command>
```

`HANDOFF.md` is single-day. Overwrite tomorrow if a new handoff is needed; otherwise it lingers as a record.

### 5. `--quick` mode

Skip steps 4. Update `SESSION-STATE.md` and `TODO.md` only. For days where you just want continuity but didn't accumulate handoff-worthy debugging context.

### 6. `--push` mode

After writing the files:

```bash
git add docs/SESSION-STATE.md docs/TODO.md docs/HANDOFF.md 2>/dev/null
git commit -m "docs: eod handoff $(date +%Y-%m-%d)"
git push
```

Use only when you genuinely want this on the remote (vacation, real handoff). Otherwise leave the changes unstaged and commit them with the next real PR.

### 7. Output

Show:
1. **Files updated:** list with paths and a one-line summary of what changed in each
2. **Tomorrow's first move:** one-line suggestion based on the open items
3. If `--push`: the remote URL and commit hash

## Rules

- Never overwrite `SESSION-STATE.md` blindly. Read it, integrate today's update, write it back. Carry forward anything not yet completed.
- Don't include sensitive content in handoff files (credentials, PHI, customer-identifying data). The handoff is in git; treat it as forever-readable.
- For dmdbrands healthcare context: explicitly redact patient/device identifiers. Use `<device-1>`, `<patient-A>` or similar.
- The handoff is documentation for a human reader, not a complete log. Be specific where it matters; brief where it doesn't.
- If the day produced no commits and no meaningful state change, write a one-line entry noting "no progress today" with the reason. Don't fabricate activity.
