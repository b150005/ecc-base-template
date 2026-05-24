# Design domain — Critic checklist

> Loaded on demand from `protocol.md`. Apply every item before
> appending a `## Counter-proposal` section to a `Status: Proposed`
> ADR. Items 1-3 are process gates; items 4-9 are quality gates
> that map to the seriousness bar.

## Process gates

- [ ] **1. ADR is in `Status: Proposed`.** Counter-proposals on
  Accepted, Deprecated, or Superseded ADRs are out of scope —
  verification happens before acceptance.

- [ ] **2. ADR is in scope for the design domain.** Pure naming /
  formatting / process ADRs are skipped. The trigger conditions
  in [protocol.md §When to invoke](./protocol.md) decide.

- [ ] **3. One counter-proposal per round.** The Critic does not
  produce two competing counter-proposals in the same iteration.
  Pick the rejected alternative most likely to have been
  dismissed too quickly; commit to it.

## Quality gates (the seriousness bar)

- [ ] **4. Same Context, same constraints.** The counter-proposal
  reproduces the original ADR's `## Context` and respects every
  constraint the original treated as load-bearing.

- [ ] **5. New decision stated cleanly.** One or two sentences,
  not a paragraph of hedging.

- [ ] **6. `## Consequences` is fully populated.** At least two
  Positive bullets, at least one Negative, at least one Neutral.
  Vague phrases like "may have downsides" are flagged.

- [ ] **7. Different evidence base.** External citations use a
  different vendor docs section, release tag, benchmark, or RFC
  than the original ADR cited. Same source paraphrased
  differently does not count.

- [ ] **8. Counter does not recommend the original choice.** If
  the Critic genuinely cannot find a serious alternative, that
  is a finding on the original ADR's framing — surface it that
  way, don't fake a counter.

- [ ] **9. Primary-source citations only.** External claims cite
  sources from the shared allowlist
  ([../research/checklist.md §Allowlist](../research/checklist.md)).
  Secondary sources are disqualifying.

## How to score

| All items checked | One quality gate failed | Two or more quality gates failed |
|---|---|---|
| PASS — counter-proposal is appended; architect responds. | REQUEST CHANGES (severity MEDIUM); Critic revises within the same round. | REQUEST CHANGES (severity HIGH); Critic restarts from a different rejected alternative. |

## Allowlist (cross-domain)

The shared primary-source allowlist lives in
[../research/checklist.md §Allowlist](../research/checklist.md).
The design domain inherits it without modification.
