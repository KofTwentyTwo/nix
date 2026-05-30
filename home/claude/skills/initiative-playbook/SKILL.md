---
name: initiative-playbook
description: "Repeatable method for taking any initiative or epic from a raw direction to an engineering-ready backlog with a hard go/no-go gate. Use when framing or planning a new initiative, taking a direction or idea to an engineering-ready backlog, decomposing an initiative into epics, breaking an epic into ≤2-week stories, writing engineer-facing tickets, or running a readiness / go-no-go review on a plan. Produces a PRD, epics, stories, and a scored readiness verdict, mirrored into the tracker."
when_to_use: "When starting or planning a new initiative; decomposing an initiative into epics; breaking an epic into stories one at a time (depth-first); or gating a plan before committing a multi-week build. The method is tracker-agnostic; the dmdbrands Jira mechanics live in an appendix. Worked example: TECH-7 (me.health Website)."
argument-hint: "[--from <direction-doc>] [--epic <key>] [--gate-only]"
---

# Initiative Playbook

Take an initiative from a raw direction to an **engineering-ready backlog** with a hard go/no-go gate, one initiative (and within it, one epic) at a time. This is the **planning + handoff** method. Build and execution are out of scope here — they happen after handoff, owned by engineers, in per-initiative build docs.

The method is tracker-agnostic. The concrete Jira mechanics for the dmdbrands / Greater Goods org live in the **dmdbrands Jira mechanics** appendix below; apply them when `org = dmdbrands`. Other orgs (GitHub Issues) reuse the same phases with their own tracker primitives — see the note at the end of the appendix (not yet operationalized).

## When to invoke

- Framing a **new initiative** from a direction, idea, or mandate.
- Decomposing an initiative into **epics**.
- Breaking a single **epic into stories** (depth-first re-entry — you run phases 4 to 8 once per epic).
- Running a **readiness / go-no-go gate** on a plan before committing a multi-week build (`--gate-only`).

## Entry modes

Default (no flag): start at Phase 0/1 and walk the whole method for a new initiative.

- **`--from <direction-doc>`** — the direction is already decided. Skip Phase 0, treat Phase 1 as captured by that doc (link it, don't re-derive), and start at Phase 2.
- **`--epic <key>`** — plan a single epic under a pre-existing initiative. First confirm the parent initiative doc + this epic's doc already exist and read them for context and constraints; if they don't, you're actually at Phase 2/3, not 4. Then run Phases 4 to 8 for that one epic.
- **`--gate-only`** — run only Phase 6 (and optionally 7) against an epic whose stories are already at the Phase-5 ticket standard. Assumes Phases 2 to 5 are done; produces just the readiness review + decisions log.

## Output

Doc artifacts in the repo's `docs/`; tracked issues in the tracker (the docs are the planning record, the tracker is the engineer-facing source of truth once handed off).

- A decision memo (direction + options rejected).
- An initiative PRD (`docs/initiatives/<name>.md`) mirrored to an Initiative issue.
- Epic docs (`docs/epics/<epic>.md`) mirrored to Epic issues.
- A story breakdown doc per epic + child Story / Spike issues, engineer-facing.
- A scored **readiness review** + a resolved-decisions log.
- Dates set (dependency-sequenced) + a kickoff message to the eng-org head.

## Principles (the non-negotiables)

1. **Planning lives in-repo** (`docs/`) and is mirrored into the tracker. Once handed off, the **tracker is the engineer-facing source of truth**; the docs are the planning record.
2. **Hierarchy:** Initiative (a company bet, quarters) → Epic (months) → Story (≤ 2 weeks, one person, clearly defined). A **Spike** is a time-boxed Story for resolving unknowns.
3. **Depth-first, not breadth-first.** Fully flesh out the *foundational* epic to story level as the template, prove the shape works, then repeat for the rest. Do not half-plan everything at once.
4. **Spike-first on real unknowns**, with a **hard go/no-go** before committing any multi-week build.
5. **Tickets are written for expert engineers:** goal + grounded context + constraints + acceptance, then trust them on the *how*. **Zero process or planning leakage** in tickets (no methodology names, planning dates, internal sequence IDs, or planning-doc cross-references).
6. **Ground planning in the actual codebase**, not just the plan. Reading the real code is what catches scope errors, mis-bucketed stories, and live bugs *before* handoff.
7. **Be honest at the gate.** A readiness review's job is to find why it *isn't* ready — a rubber stamp is worthless. "Not 100% ready" should converge to "the spike hasn't run yet," not "we have unanswered questions."
8. **Estimate in days, not team-weeks.** Throughput here is AI-augmented (a senior engineer plus Claude builds far faster than a conventional team). Size stories concretely in days; keep ≤ 2 weeks as the grain ceiling, not the default unit. Do not pad dates to team-week conventions.

## The phases

Each phase names its artifact(s). Run them in order; re-enter at phase 4 for each subsequent epic.

### Phase 0 — Discovery (conditional)

**Skip this phase if the direction is already handed to you** (a decided migration, an exec mandate, a pre-validated bet). Run it only when the initiative is genuinely net-new and the problem itself is unproven.

Validate the problem before choosing a solution: who is affected, what the pain costs today, the cost of doing nothing, and the candidate approaches. Lightweight — a problem statement and an options sketch, not a full PRD. **Accelerators:** `mattpocock--to-prd` (problem framing), `phuryn--identify-assumptions-new`, `deanpeters--problem-framing-canvas`.

→ Artifact: a short discovery / problem-validation memo in `docs/`.

### Phase 1 — Direction & validation

Research the approach; decide; record *why*, including the options rejected. For a handed-down direction this is a short decision memo capturing the call and its rationale. The decision memo is the one artifact without a bundled template — keep it to a short skeleton: **the call** (what we're doing) · **why now** (the problem / trigger) · **options considered** (incl. the ones rejected and why) · **recommendation + decision** · **open risks**. For a net-new initiative, fold in the Phase-0 problem-validation (who's affected, cost of doing nothing).

→ Artifact: decision memo / plan in `docs/` (e.g. `<topic>-plan.md`).

### Phase 2 — Initiative framing

Write the initiative as a stakeholder-readable PRD: exec summary, business objective, problem, vision, scope in/out, success criteria, **named** stakeholders, assumptions, risks, dependencies, proposed epics, definition of done, and any **initiative-level constraints** (e.g. one org / one region / a PHI guardrail). Use `references/initiative-template.md`. Lead with goals and vision, not internal process. The **named stakeholders** you fill in here *are* the sponsor (Phase 7 decisions), the eng lead (Phase 8 spike scoping), and the eng-org head (Phase 8 kickoff) — if any are unknown, identifying them is a Phase-2 prerequisite, not a Phase-8 surprise. **Accelerator:** `mattpocock--to-prd`.

→ Artifact: Initiative issue + `docs/initiatives/<name>.md` (key written back into frontmatter on creation).

### Phase 3 — Epic decomposition

One epic per major workstream. Clean boundaries — every adjacent concern routed to **exactly one** epic; each epic's **"Out of scope" doubles as the boundary fence**. Use `references/epic-template.md`.

→ Artifact: Epic issues + `docs/epics/<epic>.md`, tagged with the org's product / business-unit identifiers.

### Phase 4 — Story breakdown (foundational epic first)

Humanizing-Work splitting: vertical slices, INVEST, ≤ 2 weeks, **spike-first**. Produce via **draft → adversarially verify → synthesize**, **grounded by reading the real code**. Record the splitting rationale in the doc, not the tickets. **Accelerators:** `mattpocock--to-issues`, `deanpeters--epic-breakdown-advisor`, `deanpeters--user-story-splitting`. This draft → verify → synthesize loop is a natural (optional) multi-agent fan-out: draft splits, fan out critics to check INVEST / coverage / mis-bucketing against the codebase, then synthesize (via the Workflow tool or the `superpowers:dispatching-parallel-agents` skill). A careful single-agent pass is also fine.

→ Artifact: child Stories + the breakdown doc (`docs/epics/<epic>-stories.md`).

### Phase 5 — Engineer-facing tickets

Rewrite every story to the handoff standard in `references/ticket-standard.md`. Wire dependencies as **Blocks** links. Use the **Spike** issue type for spikes.

→ Artifact: updated story descriptions + a dependency graph.

### Phase 6 — Readiness review

Adversarial, **code-grounded** go/no-go across the dimensions in `references/readiness-rubric.md`: INVEST/readiness, coverage vs reality, quality bar, future-fit, dependencies, open inputs. Output a **scored verdict + a must-fix punch-list**, split into **(a) decisions only the business can make** and **(b) plan/story edits**. Also a strong (optional) fan-out point: one critic per dimension, then synthesize.

→ Artifact: `docs/epics/readiness-review.md`.

### Phase 7 — Resolve & apply

Execute all **(b)** plan edits yourself. Run a **guided, one-question-at-a-time decision session** with the sponsor for the **(a)** decisions (always with a recommendation). Fold answers into tickets **as plain facts**. **Simplify scope where reality allows** (e.g. a low-traffic site → drop SEO-preservation ceremony).

→ Artifact: `docs/epics/readiness-decisions.md` (resolved log).

### Phase 8 — Schedule & kick off

Set start/due dates on the initiative + epics, **sequenced by dependency** (planning targets, refined after the spike). **Estimate in days** (see principle 8). Scope the first spike with the eng lead (timebox, scope, pass-rule, tester, owner). Send the kickoff comms to the eng-org head, inviting concerns.

→ Artifact: dates on the issues + the kickoff message.

> **After handoff (out of scope for this skill):** the spike runs to its hard go/no-go; on "go," the team builds epic by epic and re-baselines dates after the spike. That execution lives in per-initiative build docs and execution skills, not here.

## The engineer-facing ticket standard (the phase-5 bar)

The full standard with an example is in `references/ticket-standard.md`. In short: lead with the work, never the process. Sections (omit empties):

`## Goal` (1 to 2 lines) · `## What exists today` (grounded — real file paths, field/env names) · `## Scope` (outcome bullets) · `## Out of scope` (delegated **by tracker key**) · `## Dependencies` (keys + named inputs) · `## Open inputs` (only real unknowns, named) · `## Acceptance` (Given/When/Then).

**Never in a ticket:** splitting-pattern names, planning dates, "found while breaking down / corrected", internal sequence IDs (`S5a`/`DP1`), planning-doc references, or a methodology footer. Reference siblings only by tracker key. Assume senior engineers: state outcomes + constraints, not step-by-step recipes.

## Output discipline (every generated ticket and doc)

- **Never use `--` (double dash) in prose.** Use an em dash (`—`) or proper punctuation. (CLI flags like `--flake` are literal code and exempt.)
- Lowercase, plain language; no methodology jargon in tracker-facing text.

## dmdbrands Jira mechanics (apply when org = dmdbrands)

The org → tracker rule (`~/.ai/3-rules.md` §4): `dmdbrands` → Jira; `QRun-IO` / `KofTwentyTwo` → GitHub Issues. The recipe below is Jira-specific.

- **Projects:** Initiatives live in **TECH** (GGT-Mgmt). Epics + Stories in **APPS** (GGT-Applications). (Platform / CI / deploy work lives in **OPS** — orientation only; this method doesn't file there.)
- **Issue type IDs:** Initiative `10892` · Epic `10000` · Story `10007` · **Spike `10646`** · Bug `10073`.
- **Parent linkage:** set `parent = {key}` (epic → initiative, story → epic). **Never create an orphan story.**
- **Required custom fields on create:** Product `customfield_10711` (e.g. "Me Health Website" = `10894`) · Business Unit `customfield_10710` (e.g. "Me Health" = `10888`) · PHI Involved `customfield_10673` (`No` = `10834`). App / product identity is the **Product + Business Unit fields, not labels.** **Bugs also require** Bug Severity `customfield_10674` + Environment Found `customfield_10676` (e.g. "Production" = `10849`). The field IDs are stable, but the **option values vary per project** — discover the right Product / Business Unit / PHI option for *your* product via the issue-type metadata (`getJiraIssueTypeMetaWithFields`) before creating issues; don't reuse the me.health option IDs blindly.
- **Planning dates:** Start date `customfield_10015` + Due date `duedate` (YYYY-MM-DD), set on the initiative + epics, sequenced by dependency.
- **Dependencies:** "Blocks" links (inwardIssue = blocker, outwardIssue = blocked). Reconcile the formal graph to match each ticket's prose.
- **Status is unreliable.** On legacy APPS issues the Jira **status field is stale** — real status lives in `src-status-*` / `actual-status-*` labels. The coverage and readiness phases must read those labels, not the status field.
- **Bugs found during planning:** file as Bugs (severity + environment) and link "Relates" to the story that supersedes them in the rebuild.
- **Mechanics:** publish via the Atlassian MCP (`createJiraIssue` with `parent`; `createIssueLink` for relationships); accelerator skill `spillwave--jira`.

> **GitHub Issues orgs (`QRun-IO` / `KofTwentyTwo`) — not yet operationalized.** The method (phases 0 to 8) holds unchanged, but the concrete tracker recipe will be hardened the first time a non-Jira initiative actually runs; don't invent a battle-tested process before then. Provisional mapping to get oriented: Initiative → a tracking issue or milestone; Epic → an issue with native sub-issues; Story / Spike → an issue (spikes carry a `spike` label); parent linkage → native sub-issues; dependencies → "Blocked by #N" + a `blocked` label; product / business-unit identity → labels (no custom-field analog); publish via the `gh` CLI or the github MCP. Until that recipe is hardened, treat this skill as assuming a Jira org.

## Reusable checklist (per initiative)

- [ ] (If net-new) problem validated — discovery memo.
- [ ] Direction decided + recorded (decision memo).
- [ ] Initiative issue + `docs/initiatives/<name>.md` (PRD, named stakeholders, initiative-level constraints).
- [ ] Epics created, tagged (product + business unit), boundaries clean (each adjacent concern routed to one epic).
- [ ] Foundational epic broken to stories — verified (INVEST + scope + completeness), code-grounded.
- [ ] All tickets engineer-facing (no leakage, no `--`), Spike type used, dependencies wired as Blocks links.
- [ ] Readiness review run → scored verdict + punch-list (a: decisions, b: edits).
- [ ] (b) edits applied; (a) decisions resolved with the sponsor and folded into tickets as facts; scope simplified where reality allows.
- [ ] Dates set (dependency-sequenced, in days); spike scoped with the eng lead; kickoff comms sent to the eng-org head.
- [ ] Repeat phases 4 to 8 for the remaining epics, one at a time.

## Worked example — TECH-7 (me.health Website)

Reference for what "good" looks like at each step (it skipped Phase 0 — direction was handed: migrate to Zoho Sites). In the me.health repo: direction in `docs/zoho-sites-migration-plan.md`; initiative TECH-7 + `docs/initiatives/me-health-website.md`; epics APPS-1331 Port the Site (foundational, broken down first) · 1332 Developer Portal · 1333 Marketing Blog · 1334 Lead Generation Engine; 41 stories with code-grounding corrections in `docs/epics/port-the-site-stories.md`; readiness `docs/epics/readiness-review.md` (~5.3/10 → ~7.8 after the punch-list) → `docs/epics/readiness-decisions.md`; kickoff Phase-0 spike APPS-1335 (1 week, ≥ 9/10 go/no-go), eng lead Jebins P. Bugs surfaced during planning: APPS-1354 to 1357 (e.g. a duplicate-SKU data bug, a dead-code newsletter opt-in), filed + linked.

## Rules

- Don't write code and don't build. This is planning + handoff only.
- Don't create tracker issues without their parent (no orphan stories).
- Be honest at the gate — surface why it isn't ready, don't rubber-stamp.
- Ground every scope claim in the real codebase, not the plan.
- Keep all tracker-facing text free of process leakage and free of `--`.
- One initiative, and within it one epic, at a time. Depth-first.
