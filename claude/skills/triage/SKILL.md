---
name: triage
description: Diagnose codebase issues from any input — ticket, freeform, paste. Traces the codebase autonomously, confirms root cause with evidence, outputs diagnosis, then waits for user to confirm before fixing. NO fixes before root cause is confirmed.
---

# Triage — Code Diagnosis

> **THE IRON LAW: NO FIXES WITHOUT ROOT CAUSE CONFIRMED FIRST.**
> Symptom fixes are failure. Root cause first. Always.

Given any issue description (ticket, freeform, paste), trace to root cause. Output diagnosis block. Wait for confirmation. Fix only after user says go.

## Scope

**In:** correctness bugs, unexpected behavior, test failures, crashes, integration issues, latency regression, resource exhaustion (memory leak, connection pool, GC pressure)
**Out:** performance optimization requests, security audits, architecture reviews, feature requests, infra/DevOps issues

## Invocation

Paste or describe the issue after `/triage`. Claude classifies, investigates, diagnoses, waits for confirmation, then fixes.

---

## Phase 1 — Classify + Reproduce

Identify issue type AND confirm reproducibility before touching any code.

**Reproduce first:**
- Can you trigger it reliably? What are the exact steps?
- Does it happen every time, or intermittently?
- If not reproducible → gather more data, do not guess, do not fix

| Type | Signal |
|---|---|
| Stack trace / crash | Error message, exception, unhandled rejection |
| Unexpected behavior | "X should do Y but does Z" |
| Test failure | Failing assertion, expected vs actual mismatch |
| Integration issue | Two systems not communicating, missing data at boundary |
| Latency / resource bug | Regression in response time, memory growth, connection exhaustion |
| Vague / mixed | Extract the symptom, treat as unexpected behavior |

**Test failure sub-type:**
- **Regression** — was passing, now failing → check recent changes first
- **Flaky** — intermittent → suspect concurrency, timing, or state leakage
- **New** — never passed → trace logic against spec

**Environment flag:**
- Is this only in staging / prod / one region? If yes: check config, secrets, feature flags, data differences before touching code.

**Cascading failures:**
- Find the first failure, not the loudest symptom. Trace from the failing dependency, not the visible error.

---

## Phase 2 — Find Entry Point

For **production incidents** (live, users affected) — observability first:

1. **Logs** — error rate spike, last successful request, error pattern, correlation IDs
2. **Metrics** — P99 latency, queue depth, error rate by handler, resource saturation
3. **Recent changes** — deployment, config change, traffic shift (git log on suspected module)

For **isolated reports** (no live signal) — code trace:

1. **Read structural files** — routes, API definitions, service indexes, main entrypoints. Map keywords to a specific handler/controller/module.
2. **Keyword inference** — "login" → auth, "checkout" → payment, "notification" → messaging
3. **Ask one specific question** — only if both above fail: "Which service or module owns [specific flow]?"

Never ask: "Can you describe the issue more?" — extract from the ticket, ask only what the codebase cannot answer.

**Escape valve:** If root cause points outside the codebase (config, DNS, data corruption, infra drift) — stop, surface findings with evidence, do not attempt a code fix.

---

## Phase 3 — Investigate

**Before forming the first hypothesis — find a working example.**
Locate similar working code in the same codebase. Compare working vs broken line by line. List every difference, however small. Don't assume "that can't matter." This eliminates false hypotheses before you form them.

**One hypothesis at a time.**
State it clearly: "I think X is the root cause because Y." Test with the smallest possible change. One variable at a time. Never stack a second fix on an unconfirmed hypothesis.

Trace the execution path from entry point toward the symptom. Read files, follow imports, check types, run tests when available.

**For async / concurrent code:** trace across all promise chains, goroutines, or event listeners — not just the happy path. Check shared mutable state for races.

**Instrument when the failure point is ambiguous AND crosses a layer boundary.** (Single-file bugs do not need instrumentation — read the code.) When a multi-layer boundary is the suspect, add diagnostic logging at each boundary before tracing logic:

```
For each suspected boundary:
  - Log what data enters the layer
  - Log what data exits the layer
  - Check environment / config at that layer
  - Verify state before and after
Run once to gather evidence. Then analyze. Then trace the specific failing layer.
```

**Surface key findings only. No narration.** Report:
- **Repro confirmed** — how and where
- **Hypothesis ruled out** — what and why (evidence, not opinion)
- **Unexpected discovery** — missing null guards, resource leaks on error paths, silent swallowed errors
- **Blocked** — what's missing and why it matters

**Hypothesis failed:**
1. Check if repro fails because bug is environment-specific or data-dependent
2. If confirmed wrong: stop, revert reasoning, restart Phase 2 from next most likely entry point
3. Never stack a fix on a wrong hypothesis

**After 3 failed hypotheses — stop. Do not attempt a fourth.**
Each fix revealing new coupling in a different place is an architectural signal, not a local bug to chase.

Output this block and stop:

```
Architectural signal:  [pattern observed across 3 hypotheses]
Evidence:              [what moved, what coupling was revealed]
Conclusion:            Root cause is structural, not local.
Next step:             Run /feature-discovery to rethink this area before proceeding.
```

Do not attempt another fix. The problem requires redesign, not another hypothesis.

---

## Phase 4 — Terminate

### Primary path

Root cause confirmed in code. Output this block, then wait for user to say "fix it":

```
Root cause:    [one sentence — what the code does wrong and why]
Evidence:      [specific function / condition / code path]
Reproduced:    [yes — how] | [no — static analysis only]
Blast radius:  [who/what is affected and at what scale]
Data safety:   [does this cause corruption, inconsistency, or loss?]
Rollback:      [instant] | [needs migration — describe]
Proposed fix:  [one sentence]
```

Do not proceed to fix until user confirms.

If investigation was long, suggest clearing before the fix — the diagnosis block above is the full artifact needed to resume:
`/clear` then paste the diagnosis block followed by `fix it`.

### Fallback path

Trigger: can't reproduce, ambiguous code path, needs data only observable in production (live traffic, real user payloads, prod env vars).

**Always wait for approval when:** fix touches user data, transactions, authentication, or shared API contracts.

**OK to proceed without approval when:** observability confirms repro, code is clearly wrong, blast radius is low (single handler, no side effects, instant rollback).

Output this block, then wait:

```
Best hypothesis: [what and why]
Confidence:      [high / medium / low]
Blocker:         [what's missing]
Options:
  A) Proceed with fix — risk: [what could be wrong]
  B) Dig deeper — need: [specific missing information]
```

---

## Phase 5 — Fix

After user confirms:

- Minimal diff only — fix the root cause, nothing else
- No refactoring, no cleanup, no scope creep
- Follow project conventions — read sibling files if conventions not documented
- If fix touches API contracts or shared schemas: verify no live consumers break

**Self-review before done:**
- [ ] Typecheck passes, lint passes
- [ ] Acceptance criteria met, no unflagged TODOs
- [ ] Data consistency maintained — transactional invariants hold
- [ ] Backward compat — doesn't break in-flight requests or live consumers

**If bug was silent (no alert, no log):** flag it as a follow-up — "This bug had no observability. Recommend a separate commit adding [specific log/metric] so next regression is catchable." Do not bundle instrumentation into the fix commit.

---

## Red Flags — STOP and Return to Phase 2

These thoughts mean you're rationalizing. Stop.

| Thought | Reality |
|---|---|
| "Obvious fix, just try it" | Obvious symptoms have non-obvious causes. Trace first. |
| "Just one quick change" | Quick patches mask root cause. |
| "Add multiple fixes, run tests" | Can't isolate what worked. Creates new bugs. |
| "I'll investigate after confirming fix" | Untested hypotheses don't stick. |
| "Probably X, let me fix that" | Probably ≠ confirmed. |
| "I don't fully understand but this might work" | This is guessing. Return to Phase 3. |
| "One more fix attempt" (after 3 failed) | Architecture is the bug. Run /feature-discovery. |
| Each fix reveals new problem elsewhere | Stop. Architectural coupling. Run /feature-discovery. |

---

## Hard Rules

1. Never ask what you can find in the code yourself
2. Never narrate routine investigation steps
3. Never start a fix before root cause is confirmed — or user approves fallback
4. Never refactor or clean up beyond the bug scope
5. Never stack a second hypothesis on top of a wrong first — revert and re-diagnose
6. Never fix code when root cause points outside the codebase — surface findings and stop
7. Never bundle instrumentation into a bug fix commit — flag as a separate follow-up
8. Never attempt a 4th hypothesis — after 3 failed, output architectural signal block and direct to /feature-discovery
