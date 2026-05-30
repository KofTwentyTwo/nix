# Readiness review rubric (phase 6)

An **adversarial, code-grounded** go/no-go on an epic's backlog before committing a multi-week build. The review's job is to find why it *isn't* ready. A rubber stamp is worthless. "Not 100% ready" should converge to "the spike hasn't run yet," not "we still have open questions."

Run it grounded in the actual codebase and the real tracker state, not a possibly-stale status field. It's a natural multi-agent fan-out (optional): one critic per dimension, then synthesize. A single-agent pass is also fine.

## Dimensions (score each 1 to 10, with evidence)

| Dimension | What you're checking |
|---|---|
| **INVEST / readiness** | Each story independent, negotiable, valuable, estimable, small (≤ 2 wk), testable. Acceptance is real Given/When/Then. No orphan stories. |
| **Coverage vs reality** | Does the backlog actually cover the epic's scope as it exists in the code? Nothing mis-bucketed, nothing missing, no story describing code that isn't there. |
| **Quality bar** | Non-functionals present where they belong (a11y, performance, security, SEO, error handling) — as part of the relevant stories, not hand-waved or bolted on as a separate track. |
| **Future-fit** | Does the shape support the *next* epics, or does it paint us into a corner? Boundaries clean. |
| **Dependencies** | The formal dependency graph (Blocks links) matches each ticket's prose. No cycles. Spike sequenced first. |
| **Open inputs** | Every unknown is named with an owner. None are silently assumed. The list is short and converging. |

## Output

A `readiness-review.md` with:

1. **Per-dimension scores + evidence** (cite real files/keys, not impressions).
2. **A composite score** and a one-line verdict (go / not-yet / no).
3. **A must-fix punch-list, split into two buckets:**
   - **(a) Decisions only the business can make** — each phrased as a question with a *recommended* answer. These go to the sponsor in a guided, one-question-at-a-time session (phase 7).
   - **(b) Plan / story edits** — mechanical fixes you execute yourself (re-bucket, tighten acceptance, fix a dependency link, file a surfaced bug).

## Convergence

Re-score after the punch-list is applied. A healthy trajectory looks like the worked example: a first pass around the middle of the scale lifting into the high 7s once (b) edits land and (a) decisions resolve — with the only remaining gap being the spike that hasn't run yet. **Simplify scope where reality allows** (e.g. a low-traffic site → drop SEO-preservation ceremony); a lower-but-simpler scope often scores higher on readiness than a padded one.
