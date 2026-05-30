---
tracker_key:        # filled on creation (e.g. PROJ-12)
initiative:         # parent initiative key (e.g. INIT-1)
project:            # epic-level project
compliance_impact: none   # none | regulated — see ## Compliance Impact
status: draft
updated:
---

# Epic: <Epic Name>

## Summary
1 to 3 sentences: what this epic delivers and why it matters. Outcome, not implementation.

## Goal
The single outcome this epic achieves. Measurable where possible.

## Scope
### In Scope
What's included.
### Out of Scope
What's explicitly excluded, and why, briefly. **This section doubles as the boundary fence** — every adjacent concern is routed to exactly one epic, named here by its tracker key.

## Approach
The key pieces / sequence, in plain terms. Not a task list — the shape of the work. Note what engineering builds vs what the owning team runs afterward.

## Acceptance Criteria / Definition of Done
A short, testable checklist — how we know the epic is done.

## Dependencies
What this epic needs (other epics by key, accounts, sign-offs, external setup).

## Owner
Engineering (build / heavy lifts) vs the operational owner (day-to-day) split.

## Compliance Impact
For regulated domains, state the regulatory/compliance read once (e.g. PCI/PII handling, data-residency, accessibility obligation, or SAMD/PHI for regulated medical domains). `none` for a standard internal/marketing surface. Carry the result into the tracker's compliance field(s).

## Stories
_To be broken down (≤ 2-week, clearly-defined, Given/When/Then acceptance criteria). Spike-first on unknowns._
