# Quality-Gate Loop Re-entry Anchored to Roadmap Row

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.10.0

## Problem

The Development Workflow (`.claude/CLAUDE.md` §Development Workflow step 6) specifies that
code-reviewer, linter, security-reviewer, and performance-engineer validate each milestone's
implementation before it can advance. When one or more of these agents returns CRITICAL or
HIGH findings, the expected response is: `implementer` fixes the issues and the quality-gate
agents review again. This loop continues until all findings are resolved or the milestone is
dropped.

This loop is currently an **informal, undocumented interim practice.** Three gaps exist in the
formalized workflow:

1. **No named owner for loop re-entry.** When CRITICAL or HIGH findings are returned, there is
   no declared rule specifying which role initiates the fix-and-re-review cycle. The orchestrator,
   the implementer, or the quality-gate agents may each plausibly act — without a named rule,
   each session must re-derive the correct owner from contextual reading.

2. **No row-anchor invariant for the loop duration.** The Roadmap row for the milestone under
   review must remain at `◐ in-progress` throughout the quality-gate loop. ADR-014's Status-
   Transition Matrix (as formalized by milestone #07) defines `◐→☑` as conditional on "all
   quality-gate agents pass for that milestone." What is not stated is the converse: a row must
   not be flipped to `☑` — or to any other status — while the loop is ongoing, and the loop is
   understood to be a continuation of the same milestone's `◐` work, not a new milestone or a
   new row.

3. **No MECE boundary against ADR-016.** ADR-016 (cross-session progress persistence,
   milestone #03) defines `specs/NN-progress.md` as the artifact for state that must survive a
   session or compaction boundary while `◐`. A quality-gate loop that completes within a single
   session never needs a `specs/NN-progress.md` entry. A quality-gate loop that crosses a
   session boundary does. This boundary is currently implicit; no rule names it explicitly.

The orchestrator's Analyze guard (milestone #08, G1–G3) addresses the **initial dispatch**
preconditions: it requires a Roadmap row to exist, the `spec:` file to be on disk for
implementation dispatches, and the `specs/NN-progress.md` absence to be surfaced for `◐` rows.
G1–G3 do not address the **re-entry** case: a quality-gate agent has returned findings, the
orchestrator must route back to `implementer`, and the loop anchor to the originating Roadmap
row must be maintained.

An interim practice exists and is coherent — `implementer` fixes, `code-reviewer` re-reviews,
row stays `◐` — but it is undocumented, unnamed, and therefore invisible to agents executing
step 6 for the first time. The formalization #21 proposes is documentation of that practice,
not a behavior change.

## Goals

- Name the owner of quality-gate loop re-entry: the role that, upon receiving CRITICAL or HIGH
  findings from step 6, routes the fix task back to `implementer` and initiates re-review.
- State the row-anchor invariant explicitly: the Roadmap row for the milestone under review
  remains `◐ in-progress` for the entire duration of the quality-gate loop; no row transition
  is made until the loop exits (all findings resolved → `◐→☑`; milestone dropped → `◐→✗`).
- Define the MECE boundary between the quality-gate loop (in-session iteration) and ADR-016's
  `specs/NN-progress.md` mechanism (cross-session state persistence): the two mechanisms are
  complementary, not competing, and neither subsumes the other.
- State the MECE boundary against #08's G1–G3 (pre-dispatch guard for initial dispatch): G1–G3
  guard the conditions before any sub-agent is dispatched; #21's re-entry rule governs the
  routing and row-anchor behavior when a quality-gate agent returns findings during an ongoing
  `◐ in-progress` milestone.
- Confirm that the formalization codifies the interim practice already exercised across
  milestones — a documentation/ownership assignment, not a new policy.

## Non-goals

- **Changing the four sanctioned glyph values (☐ / ◐ / ☑ / ✗).** ADR-014 owns those; this
  milestone does not modify them.
- **Adding a new workflow step.** The quality-gate loop is already implicit in step 6; #21
  names the ownership and anchor invariant within that step, not a new step number.
- **Changing the role assignments of the four quality-gate agents** (code-reviewer, linter,
  security-reviewer, performance-engineer). Those roles are established and unchanged.
- **Adding a new CI detector for quality-gate loop compliance.** The loop re-entry rule is a
  process/ownership assignment; mechanically verifying that a given re-review was triggered by
  the correct owner requires audit-log infrastructure that does not exist and is not in scope.
  Whether a CI detector is warranted is deferred to the architect (see Risk R-01).
- **Designing a general workflow-state-machine engine.** #07 Non-goal precedent: #21 assigns
  ownership within the existing workflow, not a new automation layer.
- **Translating the re-entry rule to derived-repo agent configurations.** That is a fork-
  maintainer responsibility, as with #07 and #08.
- **Changing the compliance check (step 6a) trigger or ownership.** Milestone #20 defined step
  6a; #21 does not modify it.

## User stories

| As a...                    | I want to...                                                                                                           | So that...                                                                                                                                          |
|----------------------------|------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| orchestrator               | Know which role I must route to when a quality-gate agent returns CRITICAL or HIGH findings                            | I never leave CRITICAL/HIGH findings unaddressed or route the fix task ambiguously to multiple agents simultaneously                                |
| implementer                | Know that I own the fix task when re-routed by the orchestrator, and that the Roadmap row stays `◐` throughout        | I implement the fix against the same Spec without creating a new milestone or losing the row anchor                                                 |
| code-reviewer              | Know that a re-review request for the same Roadmap row is a loop continuation, not a new review context               | I apply the same milestone's AC and prior findings history when evaluating the fix, not a fresh-start review                                        |
| product-manager            | Know that the row-anchor invariant protects `◐→☑` from being flipped prematurely while CRITICAL/HIGH findings remain  | The `☑ done` glyph reliably signals a closed quality gate, not a partial or loop-aborted review                                                    |
| template maintainer        | Find the re-entry ownership and row-anchor invariant in a single named rule                                             | I can enforce loop discipline in code review by pointing to a rule, not to prior session transcripts                                                |

## Acceptance criteria

- **AC-1 — Re-entry owner named:**
  Given a Roadmap row at `◐ in-progress` **when** any quality-gate agent (code-reviewer,
  linter, security-reviewer, or performance-engineer) returns one or more CRITICAL or HIGH
  findings **then** the rule specifies that the orchestrator routes the fix task back to
  `implementer`, and that `implementer` owns the fix action. No other agent may self-assign the
  fix unilaterally without orchestrator routing.

- **AC-2 — Row-anchor invariant stated:**
  Given a Roadmap row at `◐ in-progress` that is under active quality-gate review **when** the
  quality-gate loop is ongoing (one or more rounds of fix-and-re-review have occurred or are
  occurring) **then** the Roadmap row remains `◐ in-progress` for the entire loop duration;
  no actor flips the row to `☑`, `✗`, or `☐` while the loop is ongoing. The row is flipped to
  `☑ done` only when all quality-gate agents pass for that milestone (per #07 AC-2); it is
  flipped to `✗ dropped` only when the drop decision is made (per #07 AC-3/AC-4).

- **AC-3 — Compatibility with #07 AC-2 (◐→☑ gate condition):**
  Given the `◐→☑` condition defined in #07 ("all quality-gate agents pass for that milestone")
  **when** the formalized re-entry rule is applied **then** the two rules are consistent: the
  re-entry rule prevents premature `◐→☑` by requiring the loop to continue until all CRITICAL/
  HIGH findings are resolved; the `◐→☑` flip is the **exit condition** of the loop, not a
  mid-loop action.

- **AC-4 — MECE boundary with ADR-016 progress file stated:**
  Given the quality-gate loop is executing within a single session **when** no session or
  compaction boundary is crossed **then** `specs/NN-progress.md` is not created solely because
  a quality-gate loop round occurred; the progress file is reserved for cross-session
  persistence (per ADR-016). Given the quality-gate loop crosses a session or compaction
  boundary **when** the milestone is still `◐ in-progress` at that boundary **then** the
  ADR-016 boundary-trigger applies: `specs/NN-progress.md` is created (or updated) at that
  boundary by `product-manager` or `implementer`, covering the loop's current state. The two
  mechanisms operate on different triggers and are non-overlapping.

- **AC-5 — MECE boundary with #08 G1–G3 (pre-dispatch guard) stated:**
  Given the orchestrator's G1–G3 guard (milestone #08) governs pre-dispatch preconditions for
  **initial dispatch** **when** a quality-gate agent returns findings during an ongoing `◐`
  milestone **then** the re-entry routing (this milestone) is the applicable rule, not G1–G3.
  G1–G3 check whether a row, Spec, and progress file exist before dispatch begins; #21's
  re-entry rule governs what happens after a quality-gate agent has already received and
  reviewed an implementation. The two rules are non-overlapping in trigger point.

- **AC-6 — Structural decision documented in writing:**
  Given the structural questions deferred to the architect (see Risk R-01) **when** the
  architect completes the design step **then** either (a) a new ADR-023 exists and documents <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
  the re-entry ownership assignment, the row-anchor invariant, placement, and agent-prompt
  impact; or (b) an existing ADR (ADR-014 or ADR-007 or another) receives an amendment
  explicitly addressing those questions. The Spec does not prescribe the path the architect
  takes; AC-6 is satisfied when either (a) or (b) exists on disk and contains the structural
  resolution. The architect applies the ADR-018 Alternative-B triad discriminator.

- **AC-7 — Seven canonical detectors all EXIT=0:**
  Given the seven canonical detectors (`check-bilingual-parity.sh`,
  `check-dangling-refs.sh`, `check-ecc-delegation-consistency.sh`,
  `check-roadmap-drift.sh`, `check-ref-allow-expiry.sh`,
  `check-research-tier-auth.sh`, `check-skill-invariants.sh`), when each
  is run against the post-#21 repository state, then all seven exit with
  code 0. If this milestone introduces an eighth detector, AC-7 extends
  to include it.

- **AC-8 — Eight canonical test suites all pass:**
  Given the eight canonical test suites (`test-check-bilingual-parity.sh`,
  `test-check-dangling-refs.sh`, `test-check-ecc-delegation-consistency.sh`,
  `test-check-ref-allow-expiry.sh`, `test-check-roadmap-drift.sh`,
  `test-check-research-tier-auth.sh`, `test-coverage-threshold.sh`,
  `test-init-sh-roadmap-cleanup.sh`), when each is run against the post-#21
  repository state, then all eight pass without modification to existing test
  logic. If this milestone introduces a ninth test suite, AC-8 extends to
  include it.

- **AC-9 — Roadmap row #21 reflects ship state:**
  Given the post-#21 commit, when `.claude/CLAUDE.md` is read, then
  Roadmap row #21 shows `☑ done`, the `spec:` link resolves to
  `specs/21-quality-gate-row-anchor.md`, and if a new ADR was issued,
  the `adr:` link resolves to `.claude/meta/adr/023-*.md`.

- **AC-10 — CHANGELOG entry present:**
  Given the post-#21 state after step 7, when `CHANGELOG.md` is read,
  then an entry under `## [Unreleased]` records the quality-gate loop
  re-entry formalization. The technical-writer authors this entry at step 7.

- **AC-11 — JA sibling heading-tree parity:**
  Given the post-#21 state after step 7, when `specs/21-quality-gate-row-anchor.ja.md`
  is read, then its heading tree matches the EN Spec's heading tree exactly
  (per Roadmap #06 parity ownership). The technical-writer authors this file
  at step 7.

## Key interactions

1. **Interaction with #07 (Roadmap status-transition ownership).** #07 assigns the `◐→☑` flip
   to the quality-gate close-out actor after all gate agents pass. #21's row-anchor invariant
   (AC-2) is the complementary rule: the row must not flip to `☑` while the loop is ongoing.
   Together the two rules form a complete MECE picture: #07 says when `◐→☑` is authorized;
   #21 says when it is prohibited. No overlap, no gap.

2. **Interaction with ADR-016 (cross-session progress persistence).** ADR-016 defines
   `specs/NN-progress.md` as the cross-session state carrier, boundary-triggered when a `◐`
   milestone crosses a session or compaction boundary. The quality-gate loop is an in-session
   iteration mechanism. AC-4 formalizes the MECE boundary: the loop does not create a progress
   file; the boundary trigger does. A quality-gate loop that spans a session boundary invokes
   both — the loop continues, and the progress file captures the mid-loop state for the
   resuming operator/agent. The two mechanisms are composable, not competing.

3. **Interaction with #08 (Orchestrator Analyze row-guard, G1–G3).** G1–G3 are pre-dispatch
   guards that fire before any sub-agent receives a task for a milestone. AC-5 formalizes the
   MECE boundary: G1–G3 fire at initial dispatch time; #21's re-entry rule fires when a
   quality-gate agent has already reviewed and returned findings. The trigger points are
   non-overlapping. When G1–G3 all pass and a milestone is dispatched, G1–G3 have completed
   their role; #21 governs any subsequent quality-gate loop round that milestone may require.

4. **Interaction with #13 (ECC-absent degraded-review signal).** Milestone #13 defined a
   signal for when the ECC `<lang>-reviewer` Skill is absent: the code-reviewer emits a
   degraded-review warning and the human reviewer is informed that language-depth coverage is
   reduced. #21's re-entry rule applies regardless of whether ECC Skills are present or absent —
   the loop ownership and row-anchor invariant hold in both degraded and full-coverage states.
   #13 does not alter the re-entry routing or the row-anchor invariant; #21 does not alter the
   degraded-review signal. The two milestones are non-interfering.

5. **Structural HOW deferred to architect.** Whether the re-entry rule is placed in
   `orchestrator.md` Workflow-step prose, a CLAUDE.md Roadmap Rules bullet, a new named section,
   or a combination; whether this is a new ADR-023 or an amendment of an existing ADR <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
   (ADR-014, ADR-007, or another); whether agent prompts require editing and if so which agents
   are affected; and whether the claude-md-authoring Skill's Pre/Post checklist applies to any
   resulting CLAUDE.md edit — all are deferred to the architect's forthcoming decision (see
   Risk R-01).

## Metrics

- **Leading:** After this milestone ships, every orchestrator routing decision that follows a
  quality-gate agent returning CRITICAL or HIGH findings explicitly names the re-entry owner
  and references the row-anchor invariant — verifiable in session transcripts from this
  milestone forward.
- **Leading:** Zero "row flipped to `☑` while CRITICAL or HIGH findings remain open" incidents
  in the template's own Roadmap from this milestone forward.
- **Lagging:** Reduction in "which role should fix this?" re-derivation cost per milestone,
  observable when agents begin a re-review cycle by citing the rule rather than inferring it
  from prior session transcripts.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — re-entry rule placement, ADR strategy, agent-prompt impact, CI detector necessity

**Description.** This Spec states *what* must be assigned (re-entry owner, row-anchor
invariant, MECE boundaries against ADR-016 and #08) and the acceptance criteria for a
conformant formalization. It explicitly defers the structural *how*: whether the re-entry rule
lives in orchestrator.md Workflow-step prose, a CLAUDE.md Roadmap Rules bullet, a new named
section, or a combination; whether this requires a new ADR-023 or an amendment of an existing <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
ADR (ADR-014, ADR-007, or another) — the architect applies the ADR-018 Alternative-B triad
discriminator (new contract boundary / new keying / new MECE boundary => new ADR;
consequence-clarification of an existing Decision => amendment); whether `orchestrator.md`,
`implementer.md`, or other agent prompts require direct editing; whether the claude-md-
authoring Skill's Pre/Post checklist applies to any resulting CLAUDE.md edit; and whether a
CI detector is warranted for quality-gate loop compliance (treated as a design question for the
architect, not a predetermined outcome). This pattern mirrors R-01 in
`specs/07-roadmap-status-transitions.md` and `specs/08-orchestrator-row-guard.md`.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must
specify: (a) where the re-entry ownership rule and row-anchor invariant are documented so an
agent executing step 6 encounters them without additional file reads, (b) whether this is a
new ADR-023 or an amendment (Alternative-B discriminator applied), (c) which agent prompts <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
require editing and the MECE boundary against #07 and #08 in the chosen placement, and (d)
whether a CI detector is warranted. Until that decision exists, the interim practice (orchestrator
routes to `implementer` for fix; `implementer` fixes; quality-gate agents re-review; row stays
`◐`) remains the operating rule, as it has been since step 6 was written.

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect
decision live only in this Spec file (`specs/21-quality-gate-row-anchor.md`), following the
precedent set by `specs/07-roadmap-status-transitions.md` and `specs/08-orchestrator-row-guard.md`.
They do NOT appear in `.claude/CLAUDE.md`.

### Risk R-02: ADR-016 progress file — overlap risk with quality-gate loop state

**Description.** A quality-gate loop that is mid-flight when a session ends may produce a
`specs/21-progress.md` that describes an in-loop state (e.g., "second round of code-reviewer <!-- ref-allow: hypothetical progress file; only exists if loop crosses session boundary per ADR-016 | expires: 2026-07-20 -->
re-review pending"). A resuming agent must distinguish "this loop round is the reason we have
a progress file" from "a separate blocking event caused the boundary." If the progress file
does not explicitly state loop state (current round number, which findings remain open, which
agents have cleared), the resuming agent may restart the loop from round 1, wasting effort or
re-reviewing already-cleared items.

**Mitigation.** The progress file template (`.claude/templates/progress-template.md`) should
include a loop-state field under `## Notes` (e.g., "Quality gate: round N, pending agents: X,
Y"). This is an implementation detail the `implementer` resolves at step 5 when authoring the
progress file; it does not require a Spec change. AC-4 establishes the MECE trigger boundary
as the invariant; the template extension is a natural implementation of that invariant.

### Risk R-03: Overlap with #08 G1–G3 at the MECE boundary

**Description.** A future milestone author may read G1–G3 (which include the missing-progress-
file fallback) and conclude that all quality-gate routing concerns are already covered. If the
MECE boundary between initial dispatch (G1–G3) and re-entry routing (#21) is not stated clearly
in both sets of rules, the boundary may erode over time — especially because both concern the
orchestrator's routing behavior during an `◐ in-progress` milestone.

**Mitigation.** AC-5 and Key Interaction 3 state the boundary explicitly. The architect's
placement decision for #21's rule should reference the #08 guard explicitly to make the
complementary relationship visible to future readers without requiring them to cross-read both
Specs. This boundary statement is a constraint handed to the architect, not a Spec-layer
design decision.

## Out of scope

- Changing the four sanctioned glyph values (ADR-014 owns those).
- Adding a new CI workflow file for quality-gate loop enforcement (architect decision; see
  Risk R-01).
- Modifying the compliance check step (6a) trigger or ownership (milestone #20 owns that).
- Modifying the ECC-absent degraded-review signal (milestone #13 owns that).
- Translating the re-entry rule to derived-repo orchestrator configurations (technical-writer
  in derived repos at fork time).
- CHANGELOG edit at Spec-authoring time (technical-writer at step 7).
- JA sibling authoring at Spec-authoring time (technical-writer at step 7).
- #07 (Roadmap status-transition ownership) — completed; MECE boundary noted in Key
  Interactions.
- #08 (Orchestrator Analyze row-guard) — completed; MECE boundary noted in Key Interactions.
- #20 (Commit `compliance.yml` as active default) — completed; MECE boundary confirmed:
  #19/#20 owned config-file commitment; #21 owns quality-gate loop process formalization.

## References

- Roadmap row: #21
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — §Decision Status-Transition
  Matrix (Status = `◐` while in-progress; `◐→☑` only after quality gate passes); §Consequences
  → Negative ("a formal status-transition state machine is not part of this ADR") — the gap
  this milestone partially closes for the re-entry path
- `.claude/meta/adr/016-cross-session-progress-persistence.md` — boundary-triggered progress
  file mechanism; MECE boundary with #21's in-session loop formalized in AC-4
- `specs/07-roadmap-status-transitions.md` — assigns `◐→☑` flip ownership to quality-gate
  close-out actor; #21's row-anchor invariant (AC-2) is the complementary prohibition on
  premature flipping
- `specs/08-orchestrator-row-guard.md` — G1–G3 pre-dispatch guard for initial dispatch;
  #21 governs re-entry routing after a quality-gate agent returns findings; MECE boundary
  formalized in AC-5 and Key Interaction 3
- `specs/13-ecc-absent-signal.md` — degraded-review signal for ECC-absent forks; non-
  interfering with #21's re-entry rule per Key Interaction 4
- `.claude/agents/orchestrator.md` Workflow step 6 — the quality-gate step this Spec's
  re-entry rule annotates; the interim practice this Spec formalizes is already implicit in
  step 6's description
