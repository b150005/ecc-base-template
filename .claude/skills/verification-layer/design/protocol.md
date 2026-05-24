# Design domain — protocol

> Loaded on demand from the verification-layer SKILL.md.
> Shared invariants live in `../SKILL.md`. This file states the
> design-domain specifics: the counter-proposal contract, the
> seriousness bar, the lifecycle of a counter-proposal section in
> an ADR, and the output format.

This domain corresponds to ADR-010 §`design:`.

## When to invoke

- An ADR is in `Status: Proposed` and the decision will affect more
  than the immediate change set (touches architecture, dependencies,
  data model, security boundary, deployment surface, or learning
  surface for derived projects).
- A spec / PRD has selected an approach over named alternatives and
  the rejection reasoning is one or two sentences (treat as a
  signal that "Alternatives considered" is currently a formality).

Do **not** invoke for:

- ADRs that record an already-implemented, low-reversibility choice
  (the verification cost is not recovered — the cost of changing
  course exceeds the cost of accepting the original choice).
- Pure naming / formatting / process ADRs (they have no real
  alternatives that would change downstream work).
- ADRs with `Status: Accepted` or later. Verification happens
  before acceptance, not after.

## Configuration

`.claude/verification.yml` → `design:` section:

```yaml
design:
  enabled: false              # default-off
  max_iterations: 1           # design verification produces a
                              # counter-proposal artifact, not a
                              # converged consensus; iteration
                              # rarely changes the outcome
```

When `enabled: false`, the Critic is never spawned.

## What the Critic produces

For every `Status: Proposed` ADR the Critic must produce **one
concrete counter-proposal**: a rejected alternative taken seriously,
with the same context, the same constraints, a different decision,
and a fully written `## Consequences` section. The counter-
proposal:

- Names the alternative explicitly.
- Reproduces the constraints from the original ADR's `## Context`.
- States its own decision in one or two sentences.
- Fills out Positive / Negative / Neutral consequences.
- Cites primary sources for any vendor- or technology-specific
  claim.

The counter-proposal is **not** a vote against the original
decision. It is a structured second pass that makes the rejection
explicit instead of implicit. The architect (and human reviewer)
then decide whether to:

1. Revise the original ADR in light of the counter-proposal.
2. Adopt the counter-proposal and supersede the original draft.
3. Document why the original choice still wins, in the original
   ADR's `## Alternatives considered` section, citing the
   counter-proposal.

## Lifecycle in the ADR file

The counter-proposal is appended to the same ADR draft file under
a `## Counter-proposal` section, while `Status: Proposed`. Once the
ADR moves to `Status: Accepted` (after the architect responds), the
counter-proposal stays in the file as a permanent record of what
was seriously considered. It is not deleted.

If the counter-proposal becomes the accepted decision, the original
draft is rewritten to make the counter the body and the original
choice the rejected alternative.

## Seriousness bar (the test that matters)

A counter-proposal passes the seriousness bar when **a reasonable
reader, given only the counter-proposal text and no other context,
could reproduce its reasoning and reach the same recommendation
the Critic reached.** If the text reads like "we could also have
done X, but it has obvious downsides," the bar is not met — that
is restating the rejection, not seriously considering the
alternative.

Specific failure shapes (each is a finding, severity at minimum
MEDIUM):

- The counter-proposal's `## Consequences` has fewer than two
  Positive bullets.
- The counter-proposal omits a constraint that the original ADR
  treats as load-bearing.
- The counter-proposal cites only the same sources the original
  ADR cited (no different evidence base).
- The counter-proposal recommends the original choice. (If the
  Critic genuinely cannot find a serious alternative, that is a
  finding on the original ADR's framing — the constraint set is
  too narrow to admit choice.)

## Protocol

```
[1] Generator (architect)
    - Writes the ADR draft to Status: Proposed using
      .claude/templates/adr-template.md.
    - Names alternatives in the "Alternatives considered" table.

[2] Critic (architecture-critic)
    - Reads the ADR draft.
    - Picks ONE rejected alternative — preferring the one most
      likely to have been dismissed too quickly.
    - Re-derives that alternative's reasoning from the same
      Context and constraints.
    - Cites primary sources for any vendor / technology claim;
      citations must come from a different evidence base than
      the original ADR (different release tag, different vendor
      docs section, different benchmark, etc.).
    - Appends a ## Counter-proposal section to the same ADR file
      while Status remains Proposed.

[3] Verdict
    - The counter-proposal meets the seriousness bar: PASS. The
      ADR is ready for the architect to respond to.
    - The counter-proposal does not meet the bar: REQUEST CHANGES,
      with findings keyed to the failure shapes above.

[4] No iteration by default.
    The Critic produces one counter-proposal per round; the
    architect responds. A second counter-proposal on the same ADR
    is rarely useful — if the first did not surface a real
    alternative, the constraint set itself is the issue.
```

## Output format

The Critic writes directly into the ADR draft file, appending a
`## Counter-proposal` section. The findings (seriousness-bar
violations, if any) are also recorded in the
[verification-review-template.md](../../../templates/verification-review-template.md)
artifact for traceability. Domain field: `Domain: design`.

## See also

- [checklist.md](./checklist.md) — Critic checklist for ADR review
  and counter-proposal seriousness
- [failure-modes.md](./failure-modes.md) — typical design-domain
  error patterns
- [`.claude/agents/architecture-critic.md`](../../../agents/architecture-critic.md)
  — Critic agent
- [`.claude/templates/adr-template.md`](../../../templates/adr-template.md)
  — the artifact this domain operates on
