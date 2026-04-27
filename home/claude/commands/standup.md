---
description: "Generate a morning standup brief: overnight Jira activity, GitHub PR/issue updates, failed CI runs, and Slack mentions. Pulls from Greater Goods Jira (dmdbrands), GitHub (dmdbrands + KofTwentyTwo + QRun-IO), CircleCI, and Slack."
argument-hint: "[--since <duration>] [--terse]"
---

# /standup

Brief, scannable status of what changed overnight (or since the last standup). Lead with anything that needs action; everything else is FYI.

## Defaults

- **Since:** last 18 hours (covers a typical evening + morning gap). Override with `--since 24h`, `--since 3d`, `--since "2026-04-25"`, etc.
- **Output:** sectioned summary, ordered by required action.

`--terse` mode collapses each section to one line: counts and a "needs action" flag.

## Sequence

Run all sections in parallel.

### 1. Jira (Greater Goods — dmdbrands work)

```
searchJiraIssuesUsingJql('
  cloudId: 68a7a0bf-33f1-45fb-9849-37c89267c1da,
  jql: "
    project in (MH) AND
    (
      assignee = currentUser() OR
      reporter = currentUser() OR
      watcher = currentUser()
    ) AND
    updated >= "-{since}"
    ORDER BY updated DESC
  "
')
```

For each issue: status, summary, last commenter, link.

Group by:
- **Assigned to me, status changed** (probably needs eyes today)
- **Mentioned me in a comment overnight** (probably needs reply)
- **Other watched issues that moved**

### 2. GitHub (across all 3 orgs)

```bash
# Open PRs needing my review
gh pr list --search "review-requested:@me is:open" --json number,title,repository,author,createdAt,labels

# Open PRs I authored
gh pr list --search "author:@me is:open" --json number,title,repository,reviewDecision,statusCheckRollup,updatedAt

# Issues assigned to me, updated since
gh search issues "assignee:@me is:open updated:>={since-iso-date}" --json number,title,repository,state

# Mentions overnight
gh search issues "mentions:@me updated:>={since-iso-date}" --json number,title,repository
```

Group by:
- **PRs awaiting my review** (count + the highest-priority one inline)
- **My PRs that need action** (failing checks, requested changes, no activity in N days)
- **Issues mentioning me** (link + context)

### 3. CI (CircleCI)

```
mcp__circleci-mcp-server__get_latest_pipeline_status(...)
mcp__circleci-mcp-server__find_flaky_tests(...)
```

For each project I follow:
- Latest build status on `main` and `develop`
- Failed runs since `--since`
- Flaky tests detected this week (cumulative metric, not just overnight)

Lead with anything currently red on `main` — that's a "stop everything else" item.

### 4. Slack (where MCP available)

Search overnight for mentions and DMs:

```
slack_search_public_and_private(query: "to:@me", since: "{since-iso-date}")
```

Group by:
- **DMs unread**
- **Channel mentions** (channel name + 1-line summary)
- **Threads I participated in that got new replies**

If Slack MCP isn't authenticated this session, note it and skip — don't fail.

### 5. Calendar (Google Calendar MCP, if available)

Today's events in chronological order. Highlight:
- First meeting (so the standup brief is timely vs. that)
- Any conflicts or back-to-backs
- Blocks of focus time longer than 90 min

## Output format

```
# Standup — <date>

## Needs action today
- <thing> — <why>
- ...

## Jira
- Assigned to me, moved: <count>
  - MH-123: <title> — moved to In Review by <person>
- Mentions overnight: <count>
  - MH-456: <person> asked for clarification on <topic>

## GitHub
- PRs awaiting my review: <count>
  - dmdbrands/repo#42: <title> by @author (waiting <duration>)
- My PRs: <count>
  - QRun-IO/qqq#789: <title> — <status>
- Issues mentioning me: <count>

## CI
- Currently red: <count>
  - <project> on main: <failing check>
- Recently failed (since {since}): <count>

## Slack
- DMs: <count>
- Mentions: <count>
- Active threads: <count>

## Calendar today
- 9:00 — <event>
- 11:30 — <event>
- 15:00 — <event>
- ...
```

## Rules

- Lead with action items. The user reads this in 60 seconds; the most important thing is at the top.
- Don't link-dump. Surface what matters; provide links inline only for items that need action.
- If a data source is unavailable (auth expired, MCP down), note it as `[unavailable]` rather than failing the whole standup.
- For dmdbrands healthcare context: PHI never appears in the standup. If a Jira ticket has patient identifiers in the summary (it shouldn't), redact them in the brief.
- Don't auto-respond to anything. The standup informs; the user acts.
- Default `--since` is 18h. On Mondays, expand to since-Friday-EOD by default.
