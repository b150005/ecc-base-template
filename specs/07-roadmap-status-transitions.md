# Roadmap Status-Transition Ownership Assignment

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.8.0

## Problem

ADR-014 assigns explicit write-ownership for Roadmap row content: `product-manager` creates/updates the row and the `spec:` link; `architect` adds the `adr:` link; `orchestrator` only reads. What ADR-014 does **not** assign is who is authorized to flip the row's *Status glyph* (☐ / ◐ / ☑ / ✗), and at which step in the Development Workflow that flip is the correct action.

ADR-014 §Consequences → Negative acknowledges this gap verbatim: "a formal status-transition state machine is not part of this ADR. Until then, ownership-by-artifact-producer is the [interim] only guard." An interim practice has emerged organically across milestones #03, #05, and #06: `product-manager` flips ☐→◐ at the moment it authors the Spec (the pickup moment); a quality-gate close-out actor flips ◐→☑ after the quality gate passes. This practice is coherent, sensible, and consistent with ADR-014's artifact-producer principle — but it is undocumented, unassigned by name, and therefore invisible to agents picking up a new milestone for the first time.

The result: an agent that follows ADR-014 faithfully (row + spec: link = product-manager; adr: link = architect; orchestrator reads only) has no guidance on the glyph dimension. Every milestone pickup involves re-deriving "who sets ◐?" from reading prior session transcripts rather than from a declared rule. The drift risk is an agent leaving a row at ☐ after authoring its Spec, or setting ☑ before the quality gate closes, or setting ◐→✗ without clear authority.

## Goals

- Assign explicit ownership for each of the four glyph transitions (☐→◐, ◐→☑, ◐→✗, ☑/◐→✗) to a named role and a named Development Workflow step.
- Confirm that the formalized ownership codifies the interim practice already exercised by milestones #03, #05, and #06 — a documentation/ownership formalization, not a behavior change.
- State the gate conditions that must be satisfied before each transition is valid (e.g., quality gate passing before ◐→☑).
- Identify the interaction with ADR-014's existing row/link write-ownership (the glyph transition rule must be compatible and non-contradictory).
- Identify the interaction with ADR-016's `specs/NN-progress.md` deletion trigger (which is defined as "the ◐→☑ or ◐→✗ flip" — #07 governs who owns that flip, making the two rules composable).
- State where the formalized rule will live so agents encounter it when executing the relevant workflow step (the exact placement — CLAUDE.md Roadmap Rules block, Development Workflow section, or agent prompts — is deferred to the architect).

## Non-goals

- Building a CI enforcement detector that verifies *who* flipped a glyph. #07 is the ownership *assignment*; automated enforcement of that assignment is a separate, future milestone if ever. (Note: milestone #05's status-glyph well-formedness check validates that the glyph *value* is one of the four sanctioned characters — complementary to but distinct from ownership of the flip.)
- Changing the four sanctioned glyph values (☐ / ◐ / ☑ / ✗). ADR-014 owns those; this milestone does not modify them.
- Changing any existing glyph transition behavior. The formalization codifies the practice, not a new policy.
- Designing a general workflow-state-machine engine or adding new workflow steps.
- Modifying any agent prompts directly. Whether and how agent prompts are updated is the architect's call.
- Adding a new CI workflow file. #07 is a documentation/ownership assignment, not a CI addition.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| product-manager (agent) | Authors the Spec at milestone pickup | Know that ☐→◐ is its responsibility at the Spec-authoring step, not a separate later action |
| Quality-gate close-out actor (agent) | Closes the quality gate after code-reviewer / linter / security-reviewer / performance-engineer all pass | Know it is authorized — and obligated — to flip ◐→☑ at that moment, and not before |
| orchestrator (agent) | Reads the Roadmap at the Analyze step | Trust that a ◐ row has been properly authorized to be in-progress; trust that a ☑ row has passed the quality gate |
| architect (agent) | Adds `adr:` links; may drop milestones | Know the procedure for ◐→✗ vs ☑→✗ and who initiates it |
| Template maintainer (human) | Forks and manages the template | Have a single declared rule for status transitions they can enforce in code review |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| product-manager | Know that I must flip ☐→◐ immediately after authoring the Spec at milestone pickup | The Roadmap accurately reflects in-progress work without waiting for a human to update the glyph manually |
| Quality-gate close-out actor | Know that I am authorized and required to flip ◐→☑ once all quality-gate agents pass | The ☑ glyph reliably signals "quality gate closed" rather than "someone thought it was done" |
| orchestrator | Read a ◐ row at the Analyze step and trust the Spec exists on disk | I can resolve the Spec via the Roadmap pointer without checking whether the file actually materialized |
| Template maintainer | Find a single, named rule for each glyph transition in the always-read artifact | I can enforce glyph discipline in code review by pointing to a rule, not to precedent |
| architect | Know the drop procedure (◐→✗ or ☑→✗) and who initiates it | A milestone that becomes obsolete or infeasible is marked cleanly without ambiguity about authorization |

## Acceptance criteria

- **Given** a Roadmap row at ☐ todo is picked up for a new session **when** `product-manager` authors the Spec file (`specs/NN-slug.md`) **then** `product-manager` flips the Status glyph to ◐ in-progress in the same logical action (authoring the Spec and flipping ◐ are atomic from the workflow perspective — the glyph must not remain ☐ after the Spec is on disk and the milestone is in progress).
- **Given** a Roadmap row is at ◐ in-progress **when** all quality-gate agents (code-reviewer, linter, security-reviewer, performance-engineer) have passed for that milestone **then** the quality-gate close-out actor flips the glyph to ☑ done; no other actor may flip ◐→☑.
- **Given** a Roadmap row is at ◐ in-progress and the milestone is dropped or declared infeasible **when** the drop decision is made **then** the actor holding the milestone (product-manager or orchestrator per the architect's forthcoming decision; see R-01) <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation --> flips the glyph to ✗ dropped; the row remains in the table (ADR-014: history is not rewritten).
- **Given** a Roadmap row is at ☑ done and the milestone is subsequently discovered to be infeasible or reverted **when** the reversal decision is made **then** the same drop authority (see R-01 above) <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation --> may flip ☑→✗ dropped; the row remains.
- **Given** the formalized glyph-transition ownership rule **when** compared to ADR-014's existing row/link write-ownership assignment (`product-manager` owns row + `spec:` link; `architect` owns `adr:` link; `orchestrator` only reads) **then** the glyph-transition rule is consistent with and does not contradict those assignments (the ☐→◐ flip by `product-manager` aligns with its Spec-authoring ownership; the ◐→☑ flip by the quality-gate close-out actor is compatible with ADR-014 since ADR-014 does not restrict non-row-creation writes to product-manager/architect only).
- **Given** ADR-016's `specs/NN-progress.md` deletion trigger (defined as "the ◐→☑ or ◐→✗ flip") **when** the formalized glyph-transition ownership is applied **then** the two rules are composable: the actor authorized by #07 to perform ◐→☑ or ◐→✗ is also the actor responsible for ensuring `specs/NN-progress.md` is deleted at that moment (per ADR-016); there is no ownership gap between the flip and the deletion.
- **Given** the interim practice exercised by milestones #03, #05, and #06 (product-manager sets ◐ at Spec authoring; quality gate close-out sets ☑ after gate) **when** the formalized rule is applied to those historical milestones **then** every historical flip is retroactively valid under the rule — confirming this is a documentation/ownership formalization, not a behavior change.
- **Given** the formalized rule **when** documented in the location determined by the architect's decision **then** an agent executing the relevant workflow step encounters the rule without reading any additional file beyond what that step already requires (the exact location is deferred to the architect; see R-01). <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->

## Key interactions

1. The interim status-transition practice this Spec formalizes has been exercised three times: milestone #03 (product-manager set ◐ at Spec authoring for ADR-016 design session; implementer set ☑ after quality gate), milestone #05 (same pattern for ADR-017 design session), and milestone #06 (same pattern for ADR-018 design session). The formalization does not change the pattern — it names it.
2. This Spec itself is authored by `product-manager` in the same act that flips Roadmap row #07 from ☐ to ◐, exercising the very interim practice being formalized. That self-referential execution is intentional and constitutes empirical evidence that the rule is coherent under its own terms.
3. The interaction with milestone #05 (Roadmap drift-detection CI, ADR-017): #05 validates that each Status glyph is one of the four sanctioned characters — it checks *what* the glyph contains. #07 assigns *who* may change it and *when*. The two checks are complementary and non-overlapping in scope.
4. The interaction with ADR-016 (cross-session progress persistence, milestone #03): ADR-016 defines `specs/NN-progress.md` deletion as triggered by "the ◐→☑ or ◐→✗ flip." #07 governs the ownership of exactly those flips. The two rules are composable: the authorized flip-owner (per #07) also owns the deletion trigger (per ADR-016). No ownership gap exists.
5. The precise ownership matrix (which role owns the drop transitions; whether the quality-gate close-out actor is a named role or a compound role; whether the rule lives in CLAUDE.md Roadmap Rules, the Development Workflow section, agent prompts, or all three; whether the claude-md-authoring Skill checklist must be followed for the CLAUDE.md edit) is explicitly deferred to the architect's forthcoming decision. <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->
6. No CI workflow file is required by this milestone. The glyph-transition ownership rule is a process/documentation artifact, not an automated enforcement layer.

## Metrics

- **Leading:** After this milestone ships, every new milestone pickup includes the ☐→◐ flip by `product-manager` in the same session as Spec authoring — verifiable by auditing the git history of CLAUDE.md against the Spec authoring commit.
- **Leading:** Zero "row left at ☐ after Spec is on disk" incidents in the template's own Roadmap from this milestone forward.
- **Lagging:** Reduction in "which actor was supposed to flip the glyph?" re-derivation cost per milestone, observable in session transcripts when agents begin a new milestone by reading the rule rather than inferring it from prior sessions.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — ownership matrix, placement, agent-prompt impact, Skill necessity <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->

**Description.** This Spec states *what* must be assigned (four glyph transitions, named owning roles, gate conditions, compatibility with ADR-014 and ADR-016) and the acceptance criteria for a conformant formalization. It explicitly defers the structural *how*: whether the formalization is an ADR-014 amendment or a new ADR-019 (forthcoming architect decision); <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation --> the exact ownership matrix for the drop transitions (◐→✗ and ☑→✗) and whether that is product-manager, orchestrator, or a shared authority; whether and how agent prompts require updates; and whether the claude-md-authoring Skill's Pre/Post checklist must be followed for any CLAUDE.md edit that results. This mirrors the pattern used by the R-01 section of `specs/05-roadmap-drift-detection-ci.md` (deferring structural keying to ADR-017) and the R-01 section of `specs/06-bilingual-parity-detector.md` (deferring to ADR-018).

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) which role(s) own the ◐→✗ and ☑→✗ drop transitions, (b) where the formalized rule is documented so agents encounter it without additional file reads at the relevant workflow step, (c) whether this is an ADR-014 amendment or a new ADR-019 (forthcoming architect decision), and (d) whether agent prompt edits are required and which agents are affected. <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation --> Until that decision exists, the interim practice (product-manager sets ◐ at Spec authoring; quality-gate actor sets ☑ at gate close; drop authority is informal) remains the operating rule, as it has been since ADR-014 was accepted.

**Note:** The `<!-- ref-allow: -->` suppressions on the lines referencing the forthcoming architect decision live only in this Spec file (`specs/07-roadmap-status-transitions.md`), following the precedent set by `specs/05-roadmap-drift-detection-ci.md` for ADR-017 and `specs/06-bilingual-parity-detector.md` for ADR-018. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Self-referential application at authoring time

**Description.** This Spec is authored by `product-manager` in the session that picks up milestone #07, and the ☐→◐ flip is executed in that same session. The formalization therefore depends on the interim practice being correct before the formal rule exists on disk. If the interim practice were wrong, this Spec's own authoring would be wrong.

**Mitigation.** The interim practice is grounded in ADR-014's artifact-producer principle ("ownership-by-artifact-producer is the [interim] only guard") and has been exercised consistently across #03, #05, and #06. The self-referential application is evidence of coherence, not circularity: the rule correctly predicts its own application at authoring time.

### Risk R-03: Scope overlap with #05 glyph well-formedness check

**Description.** Milestone #05's `check-roadmap-drift.sh` validates that each Status glyph is one of the four sanctioned characters (☐ / ◐ / ☑ / ✗). #07 assigns who may set those glyphs and when. There is a narrow conceptual adjacency: both concern glyph discipline. A future reader might confuse "glyph validity" (#05) with "glyph flip authorization" (#07).

**Mitigation.** The MECE boundary is clean: #05 answers "is the glyph value legal?" (a character-level check automatable in CI); #07 answers "who set it and were they authorized?" (a process-level assignment that cannot be automated without audit-log infrastructure). The architect's documentation of #07's rule should state this boundary explicitly so future milestone authors do not route a new CI character check to #07 or a new ownership assignment to #05.

## Out of scope

- CI enforcement of who flipped a glyph — the formalization assigns ownership; automated verification is a separate future milestone if ever.
- Changing the four sanctioned glyph values (ADR-014 owns those).
- Adding new Roadmap columns or changing the table format (ADR-014 owns the column contract).
- Enforcing that all ADRs carry a Roadmap back-link (that is #05's domain).
- Translating the formalized rule to derived-repo CLAUDE.md files (technical-writer task in derived repos when they fork).

## References

- ADR-014 (Roadmap index as single entry point) — §Decision "Ownership of index updates" explicitly assigns row/link write-ownership but leaves glyph-transition ownership as interim; §Consequences → Negative documents "a formal status-transition state machine is not part of this ADR. Until then, ownership-by-artifact-producer is the [interim]" — the gap this milestone closes
- ADR-016 (Cross-session progress persistence) — defines `specs/NN-progress.md` deletion as triggered by "the ◐→☑ or ◐→✗ flip"; #07 governs the ownership of exactly those flips; the two rules are composable (same actor owns both the flip and the deletion trigger)
- `specs/05-roadmap-drift-detection-ci.md` — the structural sibling whose Risks R-01 and R-04 establish the ADR-017 forward-reference pattern this Spec mirrors for the forthcoming architect decision; #05's status-glyph well-formedness check (validates glyph *value*) is the complementary CI layer to #07's ownership assignment (governs *who* may set the value)
- `specs/06-bilingual-parity-detector.md` — direct structural sibling; its Risks R-01 establishes the ADR-018 forward-reference pattern this Spec mirrors <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->
- ADR-017 (Roadmap drift detector) — the structural precedent for how an architect decision resolves a Spec's deferred structural question; the forthcoming architect decision for #07 follows the same two-session model <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->
- ADR-018 (Bilingual parity detector) — same two-session model precedent <!-- ref-allow: forthcoming architect decision for #07; authored when #07 moves to implementation -->
- Roadmap row: #07
