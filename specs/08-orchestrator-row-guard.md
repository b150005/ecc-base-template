# Orchestrator Analyze Row-Guard

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.9.0

## Problem

ADR-014 makes the Roadmap the single entry point: every milestone is a row; the linked `spec:` file is the source of truth for content. The orchestrator's Analyze step (orchestrator.md Workflow step 1) is built on this invariant — it reads the Roadmap, locates the target row, and opens the linked design source before dispatching any sub-agent.

Three failure modes exist in the current design that the Analyze step neither detects nor surfaces explicitly:

1. **No Roadmap row exists for the incoming task.** A new piece of work arrives that has not yet been added as a Roadmap row. The orchestrator has no row to locate, no `spec:` to open, and no Roadmap-grounded starting point. Under the current prose it may proceed unanchored — dispatching sub-agents against an unregistered milestone — or silently stall without a diagnostic message.

2. **The row's `spec:` link is reserved but the file does not exist on disk.** ADR-014's Spec reservation rule explicitly permits `product-manager` to reserve a `specs/NN-slug.md` path in the Roadmap at row-creation time without the file being on disk (the file is authored at pickup, not at row-creation). A ☐ todo row's reserved `spec:` link is therefore validly absent. If the orchestrator resolves such a row without detecting the absence and routes it to `implementer`, the implementer has no Spec to implement against — this is the primary ADR-014 drift vector.

3. **A `◐ in-progress` row is missing its `specs/NN-progress.md`.** orchestrator.md Workflow step 1 already includes a prose fallback: "If that file is absent, state explicitly that no progress record exists and fall back to re-deriving state from `git log`; do not assume a step silently." This prose is correct but informal and invisible at the Analyze step for new orchestrator instances reading the file for the first time. The current wording is embedded inside the step description rather than named as a discrete guard condition. Milestone #08 may formalize and strengthen it into a named guard on equal footing with the other two.

The combined gap: the Analyze step has no named, self-contained guard that checks these three preconditions before dispatching work. Agents that follow orchestrator.md faithfully have no explicit signal to stop and create a row or route to `product-manager` for Spec authoring. Every orchestrator instance must re-derive the correct behavior from contextual reading rather than from a declared rule.

## Goals

- Define what the Analyze step must guarantee before it dispatches any sub-agent for milestone work: a Roadmap row must exist for the incoming task, the row's `spec:` file must exist on disk if the row is `◐ in-progress` or being routed to `implementer`/`test-runner`, and a `◐ in-progress` row's missing progress file must be surfaced as a named condition rather than a silent assumption.
- Specify the routing outcome for each failure mode: no-row detected → surface to user and route to `product-manager` to create the row before proceeding; reserved-but-absent `spec:` detected for a non-☐ row or an implementation dispatch → route to `product-manager` to author the Spec before proceeding; missing `specs/NN-progress.md` for a `◐` row → state explicitly and fall back to `git log` re-derivation, no silent assumption.
- Ensure the guard is named and discrete so that future orchestrator instances reading the rule encounter it as a distinct pre-dispatch check rather than a contextual inference.
- State the MECE boundary against #04 (dangling-reference detector), #05 (Roadmap drift-detection CI), and #07 (glyph-transition ownership) so future milestone authors do not mis-route a related concern.

## Non-goals

- Changing the four sanctioned glyph values (☐ / ◐ / ☑ / ✗). ADR-014 owns those.
- Adding a CI check that mechanically validates the guard at commit time. #08 is about the orchestrator's runtime Analyze behavior, not a static analysis layer. The guard logic lives in orchestrator.md (or its documented rule source, as the architect decides); CI enforcement is a separate future milestone if ever.
- Auto-creating a Roadmap row on behalf of the user. The guard surfaces the missing row and routes to `product-manager`; it does not silently insert a row.
- Changing the Spec reservation rule. ADR-014's reservation rule (a `spec:` link may be reserved before the file exists) is correct; #08 exploits the distinction between a legitimately reserved link for a ☐ row and a broken invariant for a row being dispatched to implementation.
- Changing how `product-manager` authors Specs. The pickup flow is owned by #07 (glyph-transition ownership) and the Roadmap Rules block; #08 adds the orchestrator-side precondition that triggers the pickup, not the pickup protocol itself.
- Modifying any agent prompt directly. Whether and how orchestrator.md requires editing is the architect's call (see Risk R-01).

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| orchestrator (agent) | Executes the Analyze step on every task | Know the discrete preconditions that must hold before dispatching sub-agents, and the explicit routing action for each unmet condition |
| product-manager (agent) | Authors Specs and Roadmap rows at milestone pickup | Receive a clear routing signal from the orchestrator when a row is missing or a Spec must be authored before implementation begins |
| implementer (agent) | Implements against a Spec | Never receive a dispatch for a milestone whose `spec:` file does not exist on disk |
| template maintainer (human) | Maintains orchestrator.md and the Roadmap | Find the guard defined in a single named location so it can be verified in code review and inherited by derived repos |
| template adopter | Forks the template | Inherit an orchestrator whose Analyze step is guarded against the three principal failure modes without additional configuration |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| orchestrator | Detect at the Analyze step that the incoming task has no Roadmap row and route to `product-manager` to create one before proceeding | I never dispatch sub-agents for unregistered milestone work |
| orchestrator | Detect that a Roadmap row's `spec:` path does not exist on disk when I am about to dispatch to `implementer` or `test-runner`, and route to `product-manager` for Spec authoring first | No implementation begins without a Spec on disk |
| orchestrator | Name the `◐ in-progress` row's missing `specs/NN-progress.md` as a discrete guard condition and state it explicitly before falling back to `git log` re-derivation | The fallback is visible and auditable, not a silent assumption |
| product-manager | Receive a routing signal from the orchestrator when a row does not exist or a Spec must be authored | I know exactly why I have been delegated and what I must produce before the orchestrator re-dispatches |
| implementer | Never receive a task dispatch for a milestone whose Spec is absent on disk | I always have a Spec to implement against |
| template maintainer | Find the guard defined as a named, discrete pre-dispatch check in the orchestrator's rule source | I can enforce the guard in code review by pointing to a rule, not to contextual reading |

## Acceptance criteria

- **Given** an incoming task that has no corresponding Roadmap row in `.claude/CLAUDE.md` **when** the orchestrator executes the Analyze step **then** the orchestrator does not dispatch any sub-agent for milestone implementation; instead it surfaces the missing row to the user and routes to `product-manager` to create the row (and author the Spec at pickup per #07) before the orchestrator re-runs Analyze on the newly created row.
- **Given** a Roadmap row at ☐ todo whose `spec:` link is reserved but the file does not exist on disk **when** the orchestrator identifies the row and the next action would be to dispatch to `implementer` or `test-runner` **then** the orchestrator does not proceed with that dispatch; it routes to `product-manager` to author the Spec (and flip ☐→◐ per #07) before re-dispatching to `implementer` or `test-runner`. (A ☐ row whose next action is product planning or architecture does not trigger this guard — the absent Spec is expected for ☐ rows.)
- **Given** a Roadmap row at ◐ in-progress whose `spec:` link points to a file that does not exist on disk **when** the orchestrator executes the Analyze step **then** the orchestrator does not dispatch to `implementer` or `test-runner`; it routes to `product-manager` to author the missing Spec, treating this as an incomplete pickup that must be resolved before implementation can proceed.
- **Given** a Roadmap row at ◐ in-progress and the corresponding `specs/NN-progress.md` is absent **when** the orchestrator executes the Analyze step **then** the orchestrator states explicitly that no progress record exists, falls back to re-deriving state from `git log`, and does not assume any workflow step silently — this condition is named and visible in the Analyze output, not inferred from context.
- **Given** the three guard conditions are all satisfied (a Roadmap row exists; the row's `spec:` file is on disk for any implementation dispatch; a missing progress file is explicitly surfaced) **when** the orchestrator completes the Analyze step **then** it proceeds to Assess Feasibility (step 2) and the full dispatch flow as currently defined in orchestrator.md — the guard adds a pre-dispatch gate without changing the behavior of any satisfied path.
- **Given** the formalized guard **when** documented in the location determined by the architect's decision **then** an orchestrator instance reading only its normal Analyze-step inputs encounters the guard conditions without reading any additional file beyond what the Analyze step already requires (the exact location is deferred to the architect; see Risk R-01). <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->
- **Given** the MECE boundaries stated in this Spec **when** a future milestone author evaluates whether a new runtime-orchestrator concern belongs in #08 or in #04/#05/#07 **then** the boundary is unambiguous: #04 validates path references in prose at commit time; #05 validates glyph values and bidirectional ADR-link contracts at commit time; #07 assigns who may flip glyphs and when; #08 is about the orchestrator's runtime Analyze behavior when a row or Spec is missing or a progress file is absent.

## Key interactions

1. **Interaction with ADR-014 Spec reservation rule.** The reservation rule allows a `spec:` path to be reserved in the Roadmap before the file exists. #08 does not change this rule. Instead, it exploits the semantic distinction: a reserved-but-absent `spec:` for a ☐ todo row is a valid intermediate state (the Spec will be authored at pickup); a reserved-but-absent `spec:` for a row being dispatched to `implementer` or `test-runner` is an invalid intermediate state that the guard must catch.
2. **Interaction with #07 (glyph-transition ownership).** #07 assigns who flips glyphs and when; #08 defines what the orchestrator must verify before dispatching work. The two are composable: when #08's guard routes to `product-manager` to author a Spec, that authoring action triggers the ☐→◐ flip per #07. There is no ownership gap.
3. **Interaction with ADR-016 (cross-session progress persistence).** ADR-016 defines `specs/NN-progress.md` creation at the first session boundary while ◐; #08's third guard condition formalizes what the orchestrator must do when it reads a ◐ row and finds that file absent. The two rules are composable: the guard's "state explicitly and fall back to git log" behavior is consistent with ADR-016's "implementer owns updates, orchestrator only reads" write-ownership contract.
4. **Interaction with #04 (dangling-reference detector).** The #04 detector catches broken path references in document prose at commit time. It explicitly does not check Roadmap-specific runtime behavior or whether a reserved `spec:` link has been materialized. #08 is about the orchestrator's runtime logic, not a CI check; the two are non-overlapping in both scope and trigger point.
5. **Interaction with #05 (Roadmap drift-detection CI).** The #05 detector validates glyph value well-formedness and bidirectional ADR-link consistency at commit time. #08 is about runtime orchestrator behavior when row/Spec state is missing, not about static structural validity. The MECE boundary is clean: #05 asks "is the Roadmap structurally valid?" at commit time; #08 asks "are the Analyze preconditions met?" at runtime.
6. **Structural HOW deferred to architect.** Whether the guard is documented as orchestrator.md Workflow-step prose, a CLAUDE.md Roadmap Rules bullet, a new named guard section, or a combination; whether a new ADR-019 is needed or an ADR-014 amendment suffices; whether orchestrator.md requires direct editing (and if so whether claude-md-authoring Skill applies); and the MECE boundary against #04/#05/#07 in the placement — all deferred to the architect's forthcoming decision. <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->

## Metrics

- **Leading:** After this milestone ships, every orchestrator Analyze output for a new task explicitly states the result of each of the three guard conditions (row exists / absent, spec on disk / absent for implementation dispatch, progress file present / absent for ◐ row) — verifiable in session transcripts.
- **Leading:** Zero "implementer dispatched without a Spec on disk" incidents in the template's own Roadmap from this milestone forward.
- **Lagging:** Reduction in mis-routed task dispatches where an agent receives a sub-task without its required design artifact, observable in session transcripts when orchestrators surface the guard condition rather than proceeding unanchored.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — guard placement, ADR strategy, agent-prompt impact, Skill necessity <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->

**Description.** This Spec states *what* the guard must guarantee (three named preconditions, three named routing outcomes, MECE boundary against #04/#05/#07) and the acceptance criteria for a conformant implementation. It explicitly defers the structural *how*: whether the guard is documented as orchestrator.md Workflow-step prose, a CLAUDE.md Roadmap Rules bullet, a new CI detector, or a combination — and where, so the orchestrator encounters it at the Analyze step without extra file reads; whether this is a new ADR-019 or an ADR-014 amendment (the architect applies the ADR-018 Alternative-B discriminator: new detector + new MECE boundary + new keying => new ADR; consequence-clarification of an existing Decision => amendment; ADR-018 is the latest, ADR-019 is unused); <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation --> whether any agent prompt (orchestrator.md primarily) requires editing, and if so whether the claude-md-authoring Skill's Pre/Post checklist applies (orchestrator.md is a `.claude/agents/*.md` file, in the Skill's scope for "significant restructuring" but not routine single-bullet edits); and the MECE boundary documentation against #04/#05/#07 in the chosen placement. This mirrors the R-01 pattern used by `specs/07-roadmap-status-transitions.md` (deferring structural how to the architect), `specs/06-bilingual-parity-detector.md`, and `specs/05-roadmap-drift-detection-ci.md`.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) where the guard conditions are documented so the orchestrator encounters them without additional file reads at the Analyze step, (b) whether this is an ADR-014 amendment or a new ADR-019 (applying the Alternative-B discriminator), (c) whether orchestrator.md requires direct editing and which sections are affected, and (d) the explicit MECE boundary statement distinguishing #08's runtime-behavior scope from #04/#05/#07's static-analysis scopes. <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation --> Until that decision exists, the existing orchestrator.md prose (Workflow step 1, which already includes the progress-file fallback) remains the operating rule, extended by this Spec's named guard conditions as process guidance.

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/08-orchestrator-row-guard.md`), following the precedent set by `specs/07-roadmap-status-transitions.md` for its architect decision, `specs/05-roadmap-drift-detection-ci.md` for ADR-017, and `specs/06-bilingual-parity-detector.md` for ADR-018. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Guard granularity for ☐-row dispatches

**Description.** The second acceptance criterion distinguishes between a ☐ row dispatched to `implementer`/`test-runner` (guard fires) and a ☐ row dispatched to `product-manager` or `architect` (guard does not fire). The dispatching condition ("about to dispatch to implementer or test-runner") requires the orchestrator to evaluate the intended downstream agent before checking the guard — a slightly more complex precondition than a simple row-status check.

**Mitigation.** The architect's placement decision should state this dispatch-target condition explicitly, or collapse it to a simpler heuristic: "if the row is ☐ and the Spec is absent, always route to product-manager first, regardless of intended downstream agent." The simpler heuristic is safe (product-manager will author the Spec and flip ◐ before any dispatch proceeds) and avoids the need for downstream-agent introspection at guard evaluation time. The Spec intentionally does not resolve this — it is the architect's call.

### Risk R-03: Scope overlap with #05 and #04 at the MECE boundary

**Description.** #04 (dangling-reference detector) and #05 (Roadmap drift-detection CI) are static commit-time checks. #08 is a runtime orchestrator-behavior guard. A future milestone author may conflate "the orchestrator detected a missing Spec at runtime" with "the CI detected a broken path reference at commit time" or with "the CI detected a reserved-but-absent spec: link."

**Mitigation.** The MECE boundary is stated in the Goals, Acceptance criteria, and Key interactions sections of this Spec. The architect's decision should repeat this boundary in the guard's placement documentation. Note: #05's Non-goals explicitly exclude checking whether a reserved `spec:` link resolves to a file on disk (the reservation rule carve-out) — that is a runtime concern, not a structural consistency concern, and it belongs to #08.

## Out of scope

- Adding a new CI workflow file. #08 is a runtime orchestrator behavior change, not a static analysis addition.
- Changing the Spec reservation rule (ADR-014 owns this).
- Changing how `product-manager` authors a Spec at pickup (owned by #07 and the Roadmap Rules block).
- Enforcing the guard mechanically in CI (a possible future milestone, not #08).
- Translating the guard to derived-repo orchestrator configurations (technical-writer task in derived repos when they fork).
- Auto-inserting a Roadmap row when none exists (the guard surfaces the condition; a human or `product-manager` creates the row).

## References

- ADR-014 (Roadmap index as single entry point) — §Spec reservation rule (reserved-but-absent `spec:` paths for ☐ rows are explicitly valid); §Decision "Ownership of index updates" — the row/link write-ownership the guard routes through; the gap this milestone closes is the orchestrator's runtime behavior when the reservation rule's intermediate state collides with an implementation dispatch
- ADR-016 (Cross-session progress persistence) — defines `specs/NN-progress.md` as the cross-session state carrier for ◐ rows; #08 guard condition 3 formalizes the orchestrator's named behavior when this file is absent
- `specs/07-roadmap-status-transitions.md` — the structural sibling whose R-01 establishes the forward-reference pattern this Spec mirrors; also the owner of the ☐→◐ flip that the guard triggers when routing to `product-manager` for Spec authoring
- `specs/05-roadmap-drift-detection-ci.md` — the MECE boundary complement: #05 is the commit-time static check; #08 is the runtime orchestrator check; #05's Non-goals section explicitly excludes the reserved-but-absent `spec:` runtime case
- `specs/06-bilingual-parity-detector.md` — structural sibling; R-01 establishes the ADR-018 forward-reference pattern <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->
- `specs/04-dangling-reference-detector.md` — the MECE boundary complement for prose path references at commit time; does not cover Roadmap runtime behavior
- `.claude/agents/orchestrator.md` Workflow step 1 — the Analyze step this Spec guards; progress-file fallback prose at line 28 is the precursor to guard condition 3
- Roadmap row: #08
