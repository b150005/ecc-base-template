# Implementation domain — Critic checklist

> Loaded on demand from `protocol.md`. Apply every item before
> emitting a `verification-review.md` for the implementation domain.
> Items 1-4 are process gates (failing one means the verification
> run itself is invalid). Items 5-10 are quality gates (failing one
> means findings, not invalidity).

## Process gates

- [ ] **1. Read the spec, not the diff, first.** The Critic must
  derive its parallel implementation from the acceptance criteria.
  Reading the Generator's diff before writing the Critic draft is
  forbidden — it collapses the verification down to a code review.

- [ ] **2. Lowest-level approach justified.** The Critic states which
  of levels 1-4 was used and (if level > 1) why level 1 / level 2
  would have produced no meaningful delta. Climbing the ranking
  without justification is a process violation.

- [ ] **3. User-library precedence respected.** If the user, spec,
  or an existing ADR pinned a library, the review header carries
  the line `> User pinned <X>; alternatives 3-4 disabled for this
  task.` and levels 3-4 are not used.

- [ ] **4. Environment unchanged.** No new system tooling installed,
  no Docker pulls, no manifest edits, no out-of-allowlist network
  calls. If level 4 was the only candidate, a blocked-note was
  emitted instead of a comparison.

## Quality gates (findings, not invalidity)

- [ ] **5. Both implementations exercised the same test suite.**
  Running the Critic's implementation against a different test set
  produces noise, not signal.

- [ ] **6. Behavioural delta table is exhaustive.** Every test that
  produced different output, threw a different error, or differed
  in observable side effects is in the table. Tests that agreed
  are summarized as "N tests agreed" — not omitted.

- [ ] **7. Silence is broken.** If implementations agreed on every
  observable, the review states this explicitly with the phrase
  "agrees on all observable behaviour." Empty findings without
  such a statement is a process error, not a PASS.

- [ ] **8. External claims cite primary sources.** Any claim about
  framework or language behaviour ("the standard library
  guarantees X") cites a primary source URL with a retrieval date.
  Claims about the *project's own* behaviour do not need citations.

- [ ] **9. Performance comparison only when meaningful.** Reporting
  microsecond differences for code paths that run once at startup
  is noise. Performance is a finding only when the delta crosses
  a user-visible threshold (latency budget, allocation count,
  cold-start time, etc.).

- [ ] **10. The `verification-review.md` artifact is the output.**
  Pull-request comments, chat messages, or commit messages are
  not substitutes. The artifact is the deliverable.

## Why these and not others

Items 1, 2, 3, 4 are non-negotiable: each one, if dropped, lets a
common implementation-domain failure mode through. Items 5-7 catch
the "looks-like-PASS-but-isn't" pattern (different test sets, partial
delta tables, silent non-comparisons). Items 8-10 catch low-effort
output: hand-waving citations, micro-optimization theatre, and
verbal-only "this looks fine" reviews. See
[failure-modes.md](./failure-modes.md) for concrete examples.

## Allowlist (cross-domain)

External claims cite primary sources only. The shared allowlist
(framework official docs, vendor GitHub at a tag, language runtime
references, RFCs, MDN) lives in
[../research/checklist.md §Allowlist](../research/checklist.md). The
implementation domain inherits it without modification.
