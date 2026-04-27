---
name: review-pr
description: "PR review router. Classifies a pull request by size, surface area, and risk, then dispatches to the appropriate plugin or built-in review tool (Quick / Standard / Deep / Focused). Use this BEFORE any direct code-review:code-review or pr-review-toolkit:review-pr invocation. The user-level rules (3-rules.md section 15) require routing through this skill first."
when_to_use: "Any time a PR review is requested: 'review this PR', 'review PR #123', 'check this PR before merge', 'is this ready to merge', or after the user creates a PR. Always invoke before direct review-tool calls."
argument-hint: "[pr-number | branch-name | --diff]"
---

# PR Review Router

Classifies the PR and dispatches to the right reviewer. Don't review the code directly — that's the dispatched tool's job. Your job is sizing, risk assessment, and routing.

## Inputs

The PR is identified by one of:
- An explicit number (`#123`) — fetch via `gh pr view 123`
- A branch name — fetch via `gh pr view --branch <name>`
- The current branch's PR — `gh pr view`
- A local diff — `git diff <base>...HEAD` or working-tree changes if pre-PR

If you can't identify the PR, ask once and stop.

## Step 1: Gather sizing data

Run these in parallel:

```bash
gh pr view <id> --json title,body,additions,deletions,changedFiles,files,labels,baseRefName,headRefName,author,reviewRequests,statusCheckRollup
gh pr diff <id>                    # full diff for surface analysis
git log --oneline <base>..HEAD     # commit history
```

Extract:
- **Size:** `additions + deletions`
- **Surface:** `changedFiles` count
- **Top-level paths touched:** unique top-level dirs from `files[].path`
- **Risk-flag paths:** see Risk Signals below
- **CI status:** any failing checks
- **Author tenure:** new contributor vs. regular
- **Linked ticket:** in title/body (`MH-123`, `(#45)`, `Closes #45`)

## Step 2: Risk Signals

Treat these as bumping risk by one tier:

| Signal | Detection |
|---|---|
| Auth/identity | paths matching `auth/`, `login`, `oauth`, `jwt`, `session`, `permissions`, `rbac` |
| Payments / financial | `billing`, `payment`, `invoice`, `subscription`, `stripe`, `pricing` |
| Schema / migration | `migrations/`, `schema/`, `*.sql`, ddl in changes |
| Security primitives | `crypto`, `hash`, `encrypt`, `secret`, `vault`, certificates, key handling |
| Healthcare/PHI (dmdbrands) | `patient`, `clinical`, `device telemetry`, `phi`, anything HIPAA-relevant |
| Public APIs / contracts | `openapi`, `swagger`, `*.proto`, exported route handlers |
| Build/release | `Dockerfile`, `*.yml` in `.github/`, `.circleci/config.yml`, deploy scripts |
| Infrastructure | `*.tf`, `*.yaml` in `k8s/`, helm charts, `terraform/` |
| Firmware critical paths | `boot`, `bootloader`, `flash`, `partition`, `secure_boot`, `dfu`, `ota` |
| External dependencies added | new entries in `package.json`, `pom.xml`, `Cargo.toml`, `go.mod`, `west.yml` |

If the PR's diff body mentions "fixes a security issue" or includes a CVE reference, also bump.

## Step 3: Classify

| Tier | Triggers (any one) | Route to |
|---|---|---|
| **Quick** | < 100 LOC, ≤ 5 files, no risk signals, all checks passing, regular contributor | `code-review:code-review` |
| **Standard** | 100–500 LOC, OR 6–20 files, OR ≤ 1 risk signal, OR new contributor | `pr-review-toolkit:review-pr` |
| **Deep** | > 500 LOC, OR > 20 files, OR ≥ 2 risk signals, OR auth/payments/schema/firmware-critical signal, OR failing checks | `pr-review-toolkit:review-pr` + targeted analyzers (see below) + `security-review` |
| **Focused** | User asked for a specific concern ("just check the tests", "any silent failures?") | The matching focused agent (see Focused Routing) |

## Step 4: Dispatch

### Quick
Invoke `code-review:code-review` with the PR identifier. Single-pass, conventions-and-style focus.

### Standard
Invoke `pr-review-toolkit:review-pr`. The toolkit fans out specialized agents (code-reviewer, comment-analyzer, silent-failure-hunter, pr-test-analyzer, type-design-analyzer) and synthesizes findings. Pass the PR identifier and any specific user concerns.

### Deep
1. Invoke `pr-review-toolkit:review-pr` for the broad sweep.
2. Run targeted analyzers in parallel based on the risk signals:
   - Auth/security/PHI signal → `security-review` skill (built-in) on the diff
   - Schema/migration signal → review the migration sequence end-to-end (forward + rollback)
   - Test surface added/changed → `pr-review-toolkit:pr-test-analyzer`
   - Significant new error handling → `pr-review-toolkit:silent-failure-hunter`
   - New types or type-heavy refactor → `pr-review-toolkit:type-design-analyzer`
   - Public API/contract change → diff the OpenAPI/proto/exported surface and flag breaking changes
   - Firmware critical path → flag for human firmware review even if the bots are happy; note Zephyr-specific concerns (devicetree, Kconfig, ISR/thread context)
3. Consolidate findings. Order by severity. Lead with anything that should block merge.

### Focused
Map the user's request to the right tool:

| Request | Tool |
|---|---|
| "check error handling" / "any silent failures" | `pr-review-toolkit:silent-failure-hunter` |
| "test coverage" / "are the tests good" | `pr-review-toolkit:pr-test-analyzer` |
| "type design" / "are these types right" | `pr-review-toolkit:type-design-analyzer` |
| "check the comments" / "documentation accurate" | `pr-review-toolkit:comment-analyzer` |
| "security review" / "any CVEs" | `security-review` skill |
| "is this ready to merge" | run `pre-merge-checklist` skill, not a code review |

## Step 5: Summarize

Output a short header before the dispatched tool's report:

```
PR #<n>: <title>
Tier: <Quick|Standard|Deep|Focused>
Sized: <additions>/<deletions> across <files> files
Risk signals: <list or "none">
Routing to: <tool>
```

Then let the dispatched tool produce its report.

## Rules

- Don't review the code yourself in this skill. Route only.
- Don't dispatch to multiple full-spectrum reviewers (`code-review:code-review` AND `pr-review-toolkit:review-pr`) — pick one per PR. Targeted analyzers may stack on top.
- If the PR has failing CI checks, mention them in the routing header but still proceed with review (the human author can use both signals).
- If the PR is a draft, ask whether to proceed or wait.
- For dmdbrands healthcare repos, always include the security path even at Standard tier.
- Never auto-merge or auto-approve. Reviewing is recommendation; merge is a human decision.
