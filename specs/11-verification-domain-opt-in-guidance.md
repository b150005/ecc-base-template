# Opt-in Trigger Guidance for Implementation/Design Verification Domains

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.12.0

## Problem

Fork maintainers who read `.claude/verification.yml` (or its `.example` companion) find `implementation.enabled: false` and `design.enabled: false` with only a cost note — "Token consumption per change is approximately doubled" — and no guidance on *when* the doubled cost is worth paying. The comment says "derived projects opt in here," but provides no project-characteristic signals to help the fork maintainer decide whether their project is the kind for which opting in is appropriate.

The gap is distinct from the per-change runtime triggers in the domain `protocol.md` files. Those documents answer: "Once my project has opted in, on which specific changes does the Critic spawn?" Milestone #11 answers the prior, project-level question: "Under what characteristics of my project should I flip `implementation.enabled` and/or `design.enabled` to `true` at all?" No existing document in the template answers this question for a fork maintainer deciding policy at project inception or review.

## Goals

- State concrete, fork-facing project-characteristic triggers for `implementation.enabled: true` — naming team size, change-risk profile, test-oracle ownership, and similar signals a fork maintainer can evaluate without inspecting an individual change.
- State concrete, fork-facing project-characteristic triggers for `design.enabled: true` — naming ADR cadence, reversibility horizon, multi-team consumer count, and similar signals.
- Distinguish the project-adoption guidance from the per-change runtime triggers in `implementation/protocol.md` and `design/protocol.md` (`## When to invoke`) — the two are complementary, not redundant.
- Place the guidance in a location that a fork maintainer encounters at the moment of adoption without reading an additional file beyond what the adoption step already requires (the exact placement is deferred to the architect; see Risk R-01).
- Leave `.claude/verification.yml` active defaults unchanged (`implementation.enabled: false`, `design.enabled: false`). Default-off is ADR-010's accepted posture; the guidance explains the posture, it does not change it.

## Non-goals

- Adding a CI detector or check that enforces or audits which domains a fork has enabled. A new detector would create a new MECE partition violating ADR-014:1800's "documentation/convention" classification for #11. This is out of scope and must not be proposed as a consequence of this milestone.
- Duplicating the per-change runtime triggers from `implementation/protocol.md` or `design/protocol.md` (`## When to invoke`). Those triggers answer when the Critic spawns for a given change after a project has opted in. #11 answers the prior adoption-level question. The two documents must remain non-redundant.
- Changing `.claude/verification.yml` active defaults. Default-off is ADR-010's deliberate and accepted posture. This milestone adds documentation that helps fork maintainers make an informed opt-in decision; it does not alter the starting state for any project.
- Specifying the exact file or section where the guidance is placed. That is a structural placement decision owned by the architect (see Risk R-01). The acceptance criteria are verifiable regardless of final placement.
- Changing the per-change runtime trigger criteria in `implementation/protocol.md` or `design/protocol.md`. Those triggers are correct and are not in scope for this milestone.
- Providing guidance for the `research` domain or `citation_discipline` — both are default-on and their posture is already explained in `verification.yml` and `SKILL.md`.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| Fork maintainer (human) | Sets up a derived project and reads `.claude/verification.yml` to decide which domains to enable | Concrete project-characteristic signals to evaluate against their own project — not just a cost note |
| Template adopter team lead | Reviews the verification layer configuration at project inception or quarterly | A decision framework that names the project signals worth examining, without requiring deep knowledge of the GAN-loop mechanics |
| Orchestrator / product-manager (agent) | Reads CLAUDE.md at Analyze time to understand which verification domains are active | A clear statement of when default-off domains are intended to become active, to avoid ambiguity at the policy level |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| Fork maintainer | Read a short list of project characteristics that signal "enable implementation verification" | I can make the opt-in decision at project inception without trial-and-error or reading the full GAN-loop protocol |
| Fork maintainer | Read a short list of project characteristics that signal "enable design verification" | I can make the opt-in decision independently for the design domain — the two sets of triggers differ and should not be conflated |
| Template adopter team lead | See the project-adoption triggers and the per-change runtime triggers named as distinct questions | I understand which document to consult for which decision, without reading both to discover they answer different questions |
| Orchestrator / product-manager | Find the adoption-level guidance without reading an additional file beyond what the adoption step already requires | I can use it as policy context when advising on domain activation |

## Acceptance criteria

- **Given** a fork maintainer reads the location where #11's guidance is placed (the exact file and section is determined by the architect) **when** evaluating whether to set `implementation.enabled: true` **then** the guidance names at least three concrete project-characteristic triggers for the `implementation` domain (examples: non-trivial custom algorithms, small team with limited reviewer diversity, partial test-oracle ownership by the Generator) distinct from any per-change "do I spawn the Critic now?" trigger.

- **Given** a fork maintainer reads the location where #11's guidance is placed **when** evaluating whether to set `design.enabled: true` **then** the guidance names at least three concrete project-characteristic triggers for the `design` domain (examples: high ADR cadence, long architectural reversibility horizon, downstream consumers in multiple independent teams) distinct from any per-change "do I spawn the Critic now?" trigger.

- **Given** the project-adoption guidance for each domain **when** a reader compares it to the `## When to invoke` section of `implementation/protocol.md` and `design/protocol.md` **then** it is unambiguous that the guidance answers a different question: project-level policy ("should this project enable the domain?") versus change-level invocation ("for this specific change, does the Critic run?").

- **Given** the guidance for both domains **when** examined by a reviewer **then** neither section refers to or duplicates the per-change runtime triggers from the `## When to invoke` sections of `implementation/protocol.md` or `design/protocol.md`.

- **Given** `.claude/verification.yml` after #11 ships **when** a reviewer checks the active file **then** `implementation.enabled` remains `false` and `design.enabled` remains `false` — confirming that the guidance is documentation only and has not altered the default posture.

- **Given** the guidance placement **when** a fork maintainer is evaluating the verification layer configuration for adoption **then** they encounter the project-adoption guidance without reading a file that is not already part of the adoption step (i.e., the guidance is co-located with the configuration or with the Skill overview — the exact co-location is the architect's decision, but the guidance must not require a third file lookup beyond what the adoption step already mandates).

- **Given** the guidance for the `implementation` domain **when** examined for detector or CI-enforcement language **then** it contains none — confirming #11 lives in the documentation/convention layer and has not introduced a new MECE partition inconsistent with ADR-014:1800.

- **Given** the guidance for the `design` domain **when** examined for detector or CI-enforcement language **then** it contains none — and the MECE boundary between #11 (adoption guidance), #04 (path-resolution CI), #05 (Roadmap structural CI), and the per-change runtime triggers in the protocol files remains unambiguous to a future milestone author evaluating scope routing.

## Key interactions

1. **Interaction with `implementation/protocol.md` and `design/protocol.md` (`## When to invoke`).** The per-change runtime triggers in those files answer "for this specific change, does the Critic spawn?" after a project has already opted in. Milestone #11 answers the upstream question: "under what project characteristics should a fork set `enabled: true` at all?" The two are complementary. The project-adoption guidance must not replicate the per-change triggers; instead it should direct readers to those files for the subsequent question.

2. **Interaction with `.claude/verification.yml` and `verification.yml.example`.** The active config file's comment block says "derived projects opt in here" with only a cost note. The example file says "The user explicitly chose to accept this cost when ADR-010 was accepted; derived projects opt in here." Neither provides project-characteristic signals. #11's guidance closes this gap — the architect's placement decision (Risk R-01) determines whether the gap is closed by amending those comments, by adding a section to `SKILL.md`, or by another location.

3. **Interaction with `SKILL.md` (`## When to invoke`).** `SKILL.md`'s `## When to invoke` says "Per domain. Each domain's protocol.md states its own triggers." This is accurate for per-change runtime invocation but does not address the project-adoption question. #11's guidance may complement this section or be co-located with it — the architect decides.

4. **Interaction with ADR-010 (verification-layer generalization).** ADR-010 established the default-off posture for `implementation` and `design` with the rationale that "derived projects opt in." #11 does not change that posture. It adds the documentation that makes the opt-in decision informed without modifying ADR-010's Decision or Consequences.

5. **Interaction with ADR-014:1800 (MECE boundary).** The MECE table at ADR-014:1800 classifies #11 as "documentation/convention." This classification is a constraint on implementation: #11 must not introduce a CI detector, a new Roadmap structural rule, or any mechanism that would create a new MECE partition. The non-goals section codifies this constraint.

6. **Structural HOW deferred to architect.** Whether the guidance is placed as a new section in `SKILL.md` (`## Project adoption triggers`), as an amendment to the comment blocks in `verification.yml` and `verification.yml.example`, as a new standalone reference file, as an addition to CLAUDE.md's `## Development Workflow` step 3, or some combination — all deferred to the architect's forthcoming decision. The architect applies the ADR-018 Alternative-B discriminator: if the placement requires a new structural convention or a new MECE partition, a new ADR (ADR-019) is warranted; if it is a consequence-clarification or extension of ADR-010's accepted "derived projects opt in" decision, an ADR-010 amendment suffices. <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

## Metrics

- **Leading:** After this milestone ships, a fork maintainer reading the verification layer documentation for adoption decisions encounters explicit project-characteristic triggers for `implementation` and `design` without opening the per-change protocol files — verifiable from the placed guidance text.
- **Leading:** Zero "why should I enable this?" questions that require reading `implementation/protocol.md` or `design/protocol.md` in full to answer the project-level policy question.
- **Lagging:** Reduction in verification layer misconfigurations in derived repos (domain enabled without the project characteristics that justify the cost, or domain left disabled despite clearly matching characteristics), observable through fork audit over time.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — guidance placement, ADR strategy

**Description.** This Spec states *what* the guidance must cover (concrete project-characteristic triggers for each of the two default-off domains, the distinction from per-change runtime triggers, no CI enforcement, no change to active defaults) and the acceptance criteria for conformant guidance. It explicitly defers the structural *how*: where the guidance is placed so a fork maintainer encounters it at adoption without an additional file read; whether the placement requires a new ADR (ADR-019) or an ADR-010 amendment (applying the ADR-018 Alternative-B discriminator: new structural convention or new MECE partition → new ADR-019; consequence-clarification/extension of ADR-010's "derived projects opt in" Decision → ADR-010 amendment; ADR-018 is the latest consumed number, ADR-019 is unused); and whether agent prompts, `SKILL.md`, `verification.yml`, `verification.yml.example`, or the `protocol.md` files require editing as part of placement. This mirrors the R-01 pattern used by `specs/10-spec-adr-directory-pinning.md`, `specs/09-spec-filename-convention.md`, `specs/08-orchestrator-row-guard.md`, and prior structural Specs. <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) the exact file(s) and section(s) where the project-adoption guidance lands, such that a fork maintainer adopting the verification layer encounters it without opening a file not already part of the adoption step; (b) whether the placement is a new ADR-019 or an ADR-010 amendment (the Alternative-B discriminator); (c) whether the guidance is self-contained in one location or split across `SKILL.md`, `verification.yml.example`, and/or the `protocol.md` files (and if split, how the reader is directed); (d) the explicit statement that the placement does not introduce a new CI detector or create a new MECE partition inconsistent with ADR-014:1800's "documentation/convention" classification for #11. Until that decision exists, the gap identified in this Spec (cost note only, no project-characteristic triggers) remains the operating state. <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design -->

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/11-verification-domain-opt-in-guidance.md`), following the precedent set by `specs/10-spec-adr-directory-pinning.md` and `specs/09-spec-filename-convention.md`. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Scope creep toward per-change runtime triggers

**Description.** The guidance for project-adoption decisions and the per-change runtime triggers in `implementation/protocol.md` and `design/protocol.md` address adjacent questions. A future author or reviewer may conflate "when should my project enable this domain?" with "when does the Critic spawn for this specific change?" and propose merging the two into a single unified trigger list.

**Mitigation.** The Non-goals, Goals, and Key interactions sections of this Spec draw the boundary explicitly. The acceptance criteria (AC-3 and AC-4) are specifically verifiable for this distinction. If a future author proposes merging the triggers, the correct response is to route the per-change guidance to its existing home in the protocol files and keep the project-adoption guidance in the location chosen by the architect for #11.

### Risk R-03: Guidance specificity vs. project diversity

**Description.** Project-characteristic triggers that are too specific may exclude valid opt-in scenarios; triggers that are too general may not help a fork maintainer make the decision. The guidance must be concrete enough to be actionable but not so narrow that it creates false negatives.

**Mitigation.** The acceptance criteria require at least three concrete triggers per domain as a minimum specificity bar. The implementer should frame triggers as "signals that increase the value of opting in" rather than "necessary and sufficient conditions," so the list is additive and a fork maintainer can use partial match as a guide rather than a gate.

## Out of scope

- Changing `.claude/verification.yml` or `verification.yml.example` active defaults — both files' `implementation.enabled` and `design.enabled` remain `false` after this milestone ships.
- Adding a CI detector, audit check, or linting rule that inspects a fork's verification domain configuration.
- Providing guidance for the `research` domain or `citation_discipline` — both are default-on and their rationale is already explained in the existing documentation.
- Changing the per-change runtime triggers in `implementation/protocol.md` or `design/protocol.md` (`## When to invoke`) — those triggers are correct and are in scope for those files, not this milestone.
- Authoring the JA sibling (`specs/11-verification-domain-opt-in-guidance.ja.md`) — that is technical-writer's responsibility, sequenced after implementation, with heading-tree parity owned by Roadmap #06. <!-- ref-allow: the JA sibling is a forthcoming file authored by technical-writer after implementation; its absence at Spec-authoring time is by design (JA parity owned by #06) -->
- Changing ADR-010's Decision or Consequences — the default-off posture is correct and this milestone adds documentation that explains it, not documentation that disputes it.

## References

- ADR-010 (verification-layer generalization) — established `implementation` and `design` domains as default-off with "derived projects opt in" rationale; #11 adds the guidance that makes that opt-in decision informed
- ADR-014 (Roadmap index as single entry point) — §(d) MECE boundary statement at line 1800 classifies #11 as "documentation/convention"; the non-goals section enforces this classification
- `.claude/skills/verification-layer/SKILL.md` — `## When to invoke` names per-change invocation semantics; #11's project-adoption guidance complements (does not replace) that section
- `.claude/skills/verification-layer/implementation/protocol.md` — `## When to invoke` states per-change runtime triggers for the implementation domain; #11's guidance is upstream and distinct
- `.claude/skills/verification-layer/design/protocol.md` — `## When to invoke` states per-change runtime triggers for the design domain; #11's guidance is upstream and distinct
- `.claude/verification.yml` lines 52–71 — the "cost note only" gap that #11 closes: `implementation.enabled: false` and `design.enabled: false` with no project-characteristic opt-in signals
- `.claude/verification.yml.example` lines 62–101 — same gap in the annotated reference copy
- `specs/10-spec-adr-directory-pinning.md` — structural sibling; its R-01 establishes the ADR-018 Alternative-B discriminator instruction this Spec mirrors
- `specs/09-spec-filename-convention.md` — structural sibling; its R-01 and `ref-allow` precedent this Spec follows
- Roadmap row: #11
