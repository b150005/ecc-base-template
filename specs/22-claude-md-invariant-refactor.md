# CLAUDE.md Invariant-Only Refactor + Roadmap Relocation + Subagent-Dispatch / Worktree-Advisory Protocols

## Status

Approved

**Owner:** orchestrator (Agent Team consultation) / implementer
**Target release:** template v3.11.0

## Problem

The user surfaced three concerns about the template after Roadmap #01–#21
landed:

1. **Subagent dispatch prompts bloat into self-execution.** When the
   parent agent (orchestrator or main Claude) writes long, detailed
   prompts to a subagent like `Explore` or a specialist, the parent
   often ends up doing the work itself instead of waiting for the
   subagent. The failure-driving pattern is over-large CONTEXT slots
   (parent solves the problem in the act of writing the prompt) and
   the absence of any physical guardrail between dispatch and return.

2. **CLAUDE.md is a worktree write-contention surface.** The Roadmap
   table inside `.claude/CLAUDE.md` (per ADR-014) mutates as status
   glyphs flip; two worktrees flipping different rows still write to
   the same file, producing silent merge conflicts or last-write-wins
   data loss. The user wants CLAUDE.md to contain only invariant
   guidance so it is not a write target across worktrees.

3. **Orchestrator does not advise on worktree parallelism.** When
   parallelism is suitable, the orchestrator should issue per-worktree
   distinct prompts and name the shared-file owner. When it is not
   suitable, the orchestrator should say so. Today, neither happens.

These three concerns share a root cause: the template lacks both an
agreed contract for *how* subagent dispatches are shaped, and an
agreed protocol for *when* multi-worktree parallelism is recommended.

## Goals

- **G1 — Subagent dispatch contract.** Establish a structural prompt
  template (5 slots) and a behavioural rule (delegate-and-stop) that
  every parent → subagent dispatch follows. Place the rule in CLAUDE.md
  (compaction-durable) with the detailed reference under
  `.claude/meta/references/dispatch-contract.md`.
- **G2 — Worktree advisory protocol.** Establish a 6-question
  suitability rubric, a mandatory `## Worktree Recommendation` output
  block before any implementation plan, a per-worktree dispatch
  format, and a SAFE/UNSAFE write-zone partition with a designated
  Roadmap-owner worktree. Reference doc at
  `.claude/meta/references/worktree-advisory.md`.
- **G3 — CLAUDE.md invariant-only refactor.** Relocate the Roadmap
  index (table + Rules block) to a dedicated `.claude/ROADMAP.md`
  file, leaving only an invariant Roadmap pointer + write-ownership
  summary in CLAUDE.md. Withdraw the 2026-05-16 line-budget exception
  (no longer needed since the Roadmap is out).
- **G4 — Roadmap row #22 + #23.** Record this Phase A work as row #22
  (status ☑ done) and the Phase B branch-separation work as row #23
  (status ☐ todo) in `.claude/ROADMAP.md`.

## Non-goals

- Phase B (the `main` + `develop` branch split, init.sh shrink,
  template-internal artifact purge from `main`) is out of scope. It
  is its own milestone, recorded as Roadmap row #23.
- Static CI enforcement of either the dispatch contract or the
  worktree advisory protocol. Both are behavioural rules whose
  compliance is visible in transcripts but not artifact-shaped; no CI
  detector is added.
- Adding worktree-active-detection to the orchestrator (i.e. modeling
  task DAGs to decide parallelism algorithmically). The static
  6-question advisory is the v1; active detection is deferred.
- Translating the new Roadmap file to Japanese
  (`.claude/ROADMAP.md` is English-only by design; see AC-9).

## Acceptance criteria

**AC-1.** `.claude/ROADMAP.md` exists with the full 21-row historical
table moved from CLAUDE.md, plus newly-added rows #22 (`☑ done`,
this Spec) and #23 (`☐ todo`, Phase B). The file co-locates the
Rules block (write-ownership, status-glyph transitions, quality-gate
re-entry, etc.) with the data those rules govern.

**AC-2.** `.claude/CLAUDE.md` `## Roadmap` section is reduced to a
short pointer paragraph naming `.claude/ROADMAP.md` as the canonical
index plus a one-paragraph write-ownership summary. The 21-row table
is fully removed from CLAUDE.md.

**AC-3.** The 2026-05-16 (CLAUDE.md line-budget vs. the Roadmap)
amendment is withdrawn: the "Sanctioned line-budget exception"
paragraph is removed from CLAUDE.md `## CLAUDE.md authoring
guidance`. The withdrawal is recorded in ADR-014's second 2026-05-20
amendment.

**AC-4.** CLAUDE.md gains two new sections — `## Subagent dispatch
contract` (≤ 30 lines) and `## Worktree advisory protocol` (≤ 25
lines) — each carrying the rule summary and pointing at the
reference doc + ADR for the rationale.

**AC-5.** `.claude/meta/references/dispatch-contract.md` exists,
documents the 5-slot template, the MUST/MAY/MUST NOT
information-density rules, the delegate-and-stop rule (including the
permitted tool list during the wait), the pre-dispatch checklist
(4 questions), and a worked 614→174-word before/after example.

**AC-6.** `.claude/meta/references/worktree-advisory.md` exists,
documents the 6-question rubric, the `## Worktree Recommendation`
output template with two examples (single + multi), the per-worktree
shared-header + slice-block dispatch format, the Roadmap-owner-
worktree designation rule, and the full SAFE / UNSAFE write-zone
list.

**AC-7.** Two new ADRs exist:

- `.claude/meta/adr/024-subagent-dispatch-contract.md` — Status
  `Accepted — 2026-05-20`, triad 3/3 justification, full
  Context / Decision / Consequences / Alternatives / References.
- `.claude/meta/adr/025-worktree-advisory-protocol.md` — Status
  `Accepted — 2026-05-20`, triad 3/3 justification, full sections.
- Both ADRs back-link Roadmap row: #22 in `## References`.
- (ADR-023 is reserved as the deliberately-rejected counter-proposal <!-- ref-allow: ADR-023 is intentionally never created per ADR-014's first 2026-05-20 amendment — counterfactual reference -->
  per ADR-014's first 2026-05-20 amendment; the new ADRs skip to 024
  and 025.)

**AC-8.** ADR-014 receives a second 2026-05-20 amendment titled
"Roadmap relocation to `.claude/ROADMAP.md`; line-budget exception
withdrawn". The amendment runs the triad discriminator (1.5/3 →
amendment, not new ADR), documents the Invariant 2 trade-off, and
records the bilingual-posture exemption for `.claude/ROADMAP.md`.
The ADR-014 JA sibling receives a corresponding amendment preserving
EN ↔ JA heading-tree parity (#06).

**AC-9.** `.claude/skills/claude-md-authoring/invariants.md`
Invariant 2 section gains a 2026-05-20 Note documenting the trade-off:
the Invariant 2 *statement* is unchanged; what changes is which
content is governed by it. `.claude/ROADMAP.md` is **not**
Invariant-2-protected; the compensating mechanism is the orchestrator's
explicit Read at session start.

**AC-10.** `.claude/agents/orchestrator.md` Analyze step is updated:

- Reads `.claude/ROADMAP.md` (not CLAUDE.md `## Roadmap`) for the
  target row lookup.
- After G1–G3, emits a mandatory `## Worktree Recommendation` block
  (with the 6-question rubric) before any dispatch.
- A new `## Subagent dispatch contract` subsection summarizes both
  layers (5-slot template + delegate-and-stop) inline, with a pointer
  to the reference doc.

**AC-11.** Three CI check scripts are updated:

- `.claude/meta/scripts/check-roadmap-drift.sh` — parses
  `.claude/ROADMAP.md` (variable renamed `CLAUDE_MD` → `ROADMAP_MD`),
  section guard removed (whole file is the Roadmap).
- `.claude/meta/scripts/check-dangling-refs.sh` — Check 1 and Check 2
  both add `.claude/ROADMAP.md` to the scan set.
- `.claude/meta/scripts/check-bilingual-parity.sh` — no change
  needed; per-pair keying auto-excludes the EN-only ROADMAP.md.

**AC-12.** All three updated check scripts pass on the post-refactor
state: `check-roadmap-drift.sh` PASS, `check-dangling-refs.sh` PASS,
`check-bilingual-parity.sh` PASS. CLAUDE.md no longer carries Roadmap
table rows that would trip the dangling-ref check on row spec/adr
links.

## Out of scope

- Phase B (branch split + payload-only `main` + init.sh shrink).
- A new CI detector for dispatch-contract or worktree-advisory
  compliance.
- Worktree active task-DAG modeling.
- Bilingual sibling for `.claude/ROADMAP.md`.
- Re-translating the existing Roadmap rows (the JA sibling carries
  the historical amendments, not the table data, by design).

## References

- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` (and its
  second 2026-05-20 amendment) — Roadmap relocation rationale.
- `.claude/meta/adr/024-subagent-dispatch-contract.md` — dispatch
  contract rationale.
- `.claude/meta/adr/025-worktree-advisory-protocol.md` — worktree
  advisory rationale.
- `.claude/CLAUDE.md` — § Roadmap (pointer), § Subagent dispatch
  contract, § Worktree advisory protocol.
- `.claude/ROADMAP.md` — the relocated Roadmap index.
- `.claude/meta/references/dispatch-contract.md` — canonical
  dispatch-contract reference.
- `.claude/meta/references/worktree-advisory.md` — canonical
  worktree-advisory reference.
- `.claude/skills/claude-md-authoring/invariants.md` — Invariant 2
  Note added on 2026-05-20.
- `.claude/agents/orchestrator.md` — Analyze step + dispatch contract
  subsection.
- Plan file (outside repo):
  `/Users/b150005/.claude/plans/roadmap-agent-team-explore-shimmering-nygaard.md` <!-- ref-allow: plan file lives in the user's home, outside this repository -->
- Roadmap row: #22
