# ADR-025: Worktree Advisory Protocol — Suitability Rubric and Roadmap-Owner Worktree Designation

## Status

Accepted — 2026-05-20

## Context

The user observed that **CLAUDE.md** (and any file mutated during
ongoing work, such as Roadmap row status glyphs or CHANGELOG entries)
becomes a **write-contention surface** when multiple worktrees run in
parallel. Two worktrees flipping status glyphs on different Roadmap
rows still write to the same file; last-write-wins data loss and
silent merge conflicts follow.

Beyond the contention problem, the user identified a missing
advisory: the orchestrator does not currently tell the human
**whether** a proposed task is suitable for worktree parallelism, and
when parallelism IS used, does not generate per-worktree distinct
prompts that explicitly partition file ownership.

The current state in this repo:

- `.claude/agents/orchestrator.md` has no guidance on worktree usage.
- The only "worktree" mention anywhere in the template is in
  `.claude/agents/adversarial-implementer.md` (single-agent scratch
  worktree pattern for verification-layer parallel implementation),
  which is unrelated to the multi-worktree-human-coordination case.
- The `## Roadmap` table in CLAUDE.md historically held mutable status
  glyphs; ADR-014 amendment 2026-05-20 (second) relocates the index
  to `.claude/ROADMAP.md` to localize the contention surface but
  does not address the coordination question.

### Forces in tension

- **Parallelism wins** when subtasks are genuinely independent. Wall-
  clock gains can be real, especially for review-heavy refactors.
- **Parallelism loses** when shared mutable state forces serialization
  at merge time, or when human review costs eat the parallel savings.
- **Coordination overhead** of multi-worktree dispatch (distinct
  prompts, hand-off contracts, owner designation) is non-trivial; the
  rule must default toward single-worktree to avoid recommending
  parallelism by reflex.
- **Discoverability** matters: the human should see the orchestrator's
  reasoning BEFORE dispatch, so they can redirect without rolling back
  subagent work.

### Triad classification (per ADR-018 Alternative-B discriminator)

- **New contract boundary? YES.** Establishes orchestrator's
  worktree-suitability-assessment obligation and the SAFE / UNSAFE
  write-zone partition.
- **New keying / mechanism? YES.** The 6-question rubric, the
  `## Worktree Recommendation` output template, the per-worktree
  shared-header + slice-block dispatch format, and the
  Roadmap-owner-worktree designation are all new mechanisms.
- **New structural artifact? YES.** A new reference document
  (`.claude/meta/references/worktree-advisory.md`) plus a new CLAUDE.md
  section that compaction-durably documents the rule.

Triad total: **3/3** → warrants a new ADR.

## Decision

Adopt a four-part worktree advisory protocol implemented as a
runtime obligation on `orchestrator`. No CI enforcement; compliance is
visible in the transcript via the mandatory `## Worktree
Recommendation` block.

### Part 1 — Suitability rubric (6 questions)

The orchestrator answers each in Analyze:

1. **File-disjoint?** Subtasks touch disjoint file sets.
2. **Roadmap-disjoint?** Subtasks affect different Roadmap rows.
3. **State-disjoint?** Subtasks do not share mutable shared state
   (CHANGELOG, lockfiles, progress files, generated artifacts).
4. **Mergeable?** Outputs combine trivially.
5. **Reversible?** Rejecting one slice leaves the others useful.
6. **Net-faster?** Parallelism wins wall-clock once human review
   costs are counted.

Decision rule:

- Yes on all 6 → recommend `multi-worktree-N`.
- No on any of 1–3 → recommend `single-worktree` (forced — shared
  state).
- No on any of 4–6 → recommend `single-worktree` (recommended —
  parallelism does not pay).

The rubric is biased toward single-worktree. The default outcome on
ambiguity is single-worktree; multi-worktree requires affirmative
yes-on-all-six.

### Part 2 — Advisory output

Before the implementation plan block, the orchestrator emits:

```
## Worktree Recommendation

Mode: [single-worktree | multi-worktree-N]
Reason: [≤ 2 sentences citing the failed rubric question if any,
         or naming why parallelism wins if multi-worktree]
If you prefer otherwise, say so before I dispatch.
```

The advisory ALWAYS invites the human to override. The orchestrator
does not silently choose parallelism.

### Part 3 — Per-worktree dispatch format

In `multi-worktree-N` mode, the orchestrator generates one **shared
header** + N **slice blocks**. The shared header names the feature,
branch base, no-write zones, and hand-off contract. Each slice block
names a single worktree's owned file glob, success criterion, and
hand-off artifact.

### Part 4 — Roadmap-owner worktree designation

When N worktrees are used, exactly one is designated the
**Roadmap-owner worktree** in the shared header. The Roadmap-owner
exclusively writes to shared mutable files:

- `.claude/CLAUDE.md`
- `.claude/ROADMAP.md`
- `CHANGELOG.md`
- `specs/NN-progress.md`
- Lockfiles
- `README.md` / `README.ja.md`

Non-owner worktrees produce slice outputs and surface hand-off
requests (e.g. "Roadmap row #NN should flip to ☑"); the Roadmap-owner
reconciles them into single coherent updates when slices merge. This
is the structural defense against the user-observed contention failure
mode.

### Placement and inheritance

Summarized in `.claude/CLAUDE.md` § Worktree advisory protocol
(compaction-durable, ≤ 25 lines), detailed in
`.claude/meta/references/worktree-advisory.md`. Forks inherit the
protocol via CLAUDE.md. Forks may adjust the SAFE / UNSAFE zone lists
to match their own shared-state surface (e.g. add a generated API
client file) but may not weaken the rubric or skip the recommendation
output.

## Consequences

### Positive

- The user-observed write-contention failure mode is eliminated by
  the Roadmap-owner designation: only one worktree writes to the
  shared files, period.
- The mandatory `## Worktree Recommendation` block surfaces the
  parallelism decision before any subagent dispatch, giving the human
  a chance to redirect without rollback.
- The rubric's bias toward single-worktree prevents
  parallelism-by-reflex; multi-worktree only fires when the wins are
  unambiguous.
- The advisory makes orchestrator's reasoning legible — the human
  sees which rubric question failed, not just the verdict.

### Negative

- Adds one block of orchestrator output per task. Mitigation: the
  block is short (≤ 5 lines) and skimmable.
- The 6-question rubric is a judgment exercise — two reasonable
  evaluators could disagree on Q6 (net-faster) in particular.
  Mitigation: the rubric is biased toward single-worktree, so
  disagreement resolves toward the safer default.
- Multi-worktree dispatch requires the human to paste header + slice
  into N worktrees; ergonomic friction is real. Mitigation: the
  orchestrator emits paste-ready blocks; the friction is one-time
  per multi-worktree task.

### Neutral

- The protocol is not enforced by CI. Compliance is observable in
  transcripts (the human can see whether the recommendation block
  appeared and whether the Roadmap-owner was respected). No automated
  check is feasible because worktree usage is a human/orchestrator
  coordination concern, not an artifact-shape concern.
- The Roadmap-owner designation is operationalized through the
  existing dispatch-contract (ADR-024) — the orchestrator names the
  owner in the shared header it generates; non-owners receive
  CONSTRAINTS that name the no-write zones.
- The protocol composes with ADR-014's row-guard G1–G3 (#08) and
  quality-gate re-entry (#21): both fire before the advisory, on
  every dispatch path.

### Risks

- **Forks add shared files to the SAFE list incorrectly.** A fork
  that promotes a previously-shared file (e.g. CHANGELOG) to the SAFE
  list re-opens the contention hole. Mitigation: the reference doc
  enumerates the structural reason each file is in UNSAFE — it is the
  fork's responsibility to verify their replacement does not have the
  same property.
- **Orchestrator skips the rubric for "obvious" tasks.** Single-file
  edits trivially pass the rubric, and the orchestrator might be
  tempted to skip the recommendation block. Mitigation: the
  recommendation block is mandatory regardless of task size; for
  trivially-single-worktree tasks the block is one line ("Mode:
  single-worktree. Reason: single file change.").
- **Orchestrator recommends multi-worktree when human prefers
  serial.** Mitigation: the "If you prefer otherwise, say so before I
  dispatch" line is mandatory and explicitly invites override.

## Alternatives considered

| Alternative | Pros | Cons | Why not chosen |
|---|---|---|---|
| **A: 6-question rubric + Roadmap-owner designation (selected)** | Two-layer defense (advisory + structural owner); biased toward safety; transparent reasoning; forks inherit cleanly | Adds one block per task; rubric requires judgment | Selected. The two layers cover the two failure modes (silent parallelism, write contention) the user observed |
| **B: Orchestrator silently chooses parallelism by heuristic** | Less output | The human cannot redirect; failures are discovered post-merge; defeats the advisory purpose | The user's stated concern is precisely that the orchestrator should advise BEFORE dispatch, not act unilaterally |
| **C: Static rule — always single-worktree** | Maximum simplicity | Forgoes legitimate parallelism wins; the user explicitly asked for worktree support, not its prohibition | Over-corrects; the user wants advisory + coordination, not a ban |
| **D: Active dependency-graph analysis (orchestrator models task dependencies before dispatching)** | Maximally informed | Requires the orchestrator to build a full task DAG before any dispatch; architecturally complex; deferred per product-manager's "Question 3" tradeoff resolution | Out of scope for v1; the static advisory covers the 80% case where the human makes the parallelism decision |
| **E: CI lint of multi-worktree PRs for shared-file conflicts** | Mechanically enforceable | Catches the failure post-hoc after work is wasted; does not prevent the failure | Wrong time window; advisory + Roadmap-owner is the prevention layer |

## References

- `.claude/CLAUDE.md` § Worktree advisory protocol — the
  compaction-durable summary.
- `.claude/meta/references/worktree-advisory.md` — canonical reference
  with the suitability rubric table, advisory output examples, and
  full SAFE / UNSAFE zone list.
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — the
  Roadmap entry point and its 2026-05-20 second amendment, which
  relocates the Roadmap index to `.claude/ROADMAP.md` (the file most
  affected by the Roadmap-owner designation).
- `.claude/meta/adr/024-subagent-dispatch-contract.md` — the dispatch
  contract this protocol operationalizes through (per-worktree CONSTRAINTS
  naming no-write zones).
- `.claude/agents/orchestrator.md` — receives an inline Worktree
  Recommendation step in Analyze, after row-guard G1–G3.
- `.claude/agents/adversarial-implementer.md` — single-agent scratch
  worktree pattern, NOT in scope of this protocol.
- Roadmap row: #22
