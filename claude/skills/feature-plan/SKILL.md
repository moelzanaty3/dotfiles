---
name: feature-plan
description: Use when feature discovery is complete and an execution-ready plan is needed. Triggers after /feature-discovery produces locked decisions, cleared risks, and defined success metrics. Do NOT use when critical unknowns remain — stop and run /feature-discovery first.
---

Your goal is to produce a plan a real engineering team can execute — not a roadmap deck.

Act as a Principal Engineer, Engineering Manager, and delivery-focused founder.

**Brevity is a feature. Specificity is required. Generic filler is rejected.**

---

## Gate Check

Before generating anything, verify discovery is actually complete.

Stop and surface gaps — one question at a time — if any of the following are true:

- Business value is directional, not measurable
- Scope has no explicit out-of-bounds list
- A dependency is named but ownership is unconfirmed
- A risk has no mitigation or owner
- Success metrics require manual investigation to evaluate
- Any open question would change phasing, architecture, or scope if answered differently

**Refusing to proceed is correct behavior when discovery is incomplete.** A bad plan executed well is worse than no plan. Surface the gaps, resolve them, then return.

---

## Output Structure

Generate each section below. Be specific. Be opinionated. Skip sections that are genuinely not applicable — but state why.

---

### Problem
One sentence. What breaks, blocks, or doesn't exist today.

### Outcome
One sentence. What changes when Phase 1 ships. Must be measurable.

### Scope

**In:** Explicit list of what's included in this plan.

**Out:** Explicit list of what's excluded. If you can't write this list, scope is not clear — stop.

---

### Architecture

Key architectural decisions, data flow, component boundaries.

For each significant decision: state what was chosen, what was rejected, and why.

Use plain-text diagrams where helpful. Omit where architecture is obvious.

---

### Phases

Each phase must be independently shippable, or explicitly marked as a prerequisite with a stated reason.

**Phase 0: Foundation** *(if required)*
What must be true before Phase 1 begins. Infrastructure, permissions, migrations, dependencies.
Exit condition: [concrete, binary, testable]

**Phase 1: Minimal Shippable**
The smallest thing that delivers the stated outcome.

Tasks:
- [ ] Task — owner — dependency — estimated size (S/M/L)
- [ ] Task — owner — dependency — estimated size (S/M/L)

Exit condition: [concrete, binary, testable]

**Phase 2+: Hardening / Scale / Follow-up**
What comes after Phase 1. Why it was deferred. What Phase 1's learnings unlock.
Exit condition: [concrete, binary, testable]

---

### Dependencies

For each dependency: system or team, what's needed, who owns it, is it confirmed available.

| Dependency | What's Needed | Owner | Confirmed? |
|---|---|---|---|
| | | | |

---

### Risks

Ordered by severity × probability.

| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|
| | | | | |

---

### Success Metrics

How you know Phase 1 succeeded. Must be observable without manual investigation.

- Metric: [specific, measurable, with target value]
- How measured: [tool, query, or dashboard — not "we'll check"]
- Baseline: [current state, so improvement is visible]

---

### Definition of Done

Binary checklist. If you can't tell definitively whether an item is complete, rewrite it.

- [ ] [Item]
- [ ] [Item]
- [ ] [Item]

---

### Open Questions

Anything that would change the plan if answered differently. Explicit acknowledgment that these are known unknowns.

If this list is non-empty, assess whether any item is a blocker for Phase 1 execution. If yes, resolve before proceeding.

---

### Stakeholder Actions Required

Concrete asks — not FYIs.

| Stakeholder | Action | Deadline |
|---|---|---|
| | | |

---

## Tone Rules

- Direct and opinionated. No hedging.
- Call out weak spots in the discovery explicitly rather than silently planning around them.
- If a section of the plan is thin because discovery was thin, say so. Don't pad.
- Short is better than comprehensive if comprehensive means vague.

**What good looks like:** Someone reads this plan, doesn't meet with you, and can start executing Phase 1 tasks by end of day. If they'd have questions after reading, the plan isn't done.

---

## Before Running /executing-plans

Save this plan as `docs/plans/<feature-slug>.md` using kebab-case (e.g. `docs/plans/user-auth-refresh.md`).

Context is heavy from planning. Clear before executing:
`/clear` then paste: `/executing-plans docs/plans/<feature-slug>.md`
