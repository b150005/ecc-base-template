# Spec/ADR Directory Location Pin in CLAUDE.md

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.11.0

## Problem

The `## Document Templates` section of CLAUDE.md currently says: "You decide where to place the resulting documents. Single-language projects can write directly under a top-level directory of your choice (e.g. `adr/001-foo.md`); bilingual projects can split by language (e.g. `adr/en/001-foo.md`, `adr/ja/001-foo.md`). The template does not impose a layout — only the templates." This guidance is accurate for a derived project choosing its own conventions — but it leaves a gap for the template itself.

In practice, this repository pins two locations without naming them as conventions: Spec files live under `specs/` (already canonical via the ADR-014 reservation rule and the #09 filename convention) and ADR files live under `.claude/meta/adr/` (confirmed by every ADR file authored to date). The Roadmap `## Rules` block references both directories without ever declaring them as the authoritative directory convention. No document in the template states these two directories as named, pinned conventions that agents and contributors encounter at the authoring step.

The result is a split between the `## Document Templates` "you decide" guidance (accurate for forks) and the actual convention in operation in this repository (pinned). Milestone #10 resolves this by making the pinned directory locations explicit, named, and normative for this repo's dogfooding posture — while accounting for the tension with the existing free-placement guidance and delegating the reconciliation to the architect.

## Goals

- Declare `specs/` as the canonical directory for Spec files in this repository as an explicit, named convention.
- Declare `.claude/meta/adr/` as the canonical directory for ADR files in this repository as an explicit, named convention.
- State the EN/JA bilingual convention for Spec files in this repo: EN and JA siblings coexist as `specs/NN-slug.md` and `specs/NN-slug.ja.md` in the **same** `specs/` directory — not split into `specs/en/` and `specs/ja/`. Clarify that the `adr/en/` / `adr/ja/` example in `## Document Templates` is illustrative for forks, not the convention for this repo. <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
- Surface the tension between the `## Document Templates` "you decide where to place" guidance and the de-facto pinned directories, and hand the reconciliation to the architect as a named open question (see Risk R-01).
- Confirm retroactive conformance: every existing Spec file (`specs/01-*.md` through `specs/09-*.md` plus `.ja.md` siblings) and every existing ADR file (`.claude/meta/adr/001-*.md` through `.claude/meta/adr/018-*.md` plus `.ja.md` siblings) already conforms to the pinned directories — this is a convention-statement milestone, not a bulk-move milestone.
- Compose with #09 to specify the full canonical path: `specs/NN-slug.md` = `specs/` (#10's scope) + `NN-slug.md` (#09's scope). The two are MECE.

## Non-goals

- Renaming or moving any existing Spec or ADR file. All existing files already live in the pinned directories; no bulk-move work is required or in scope.
- Changing the filename convention for Spec files. The `NN-slug.md` filename form is #09's scope. #10 is about the directory, not the filename.
- Adding a new CI directory-conformance check. Whether to add such a check is a structural decision deferred to the architect (see Risk R-01). #10 is a documentation/convention-statement milestone; CI enforcement is an optional consequence.
- Changing the bilingual parity rule. Heading-tree parity between EN and JA files is owned by #06 (ADR-018). #10 does not redefine or extend that rule.
- Redefining the ADR filename convention (three-digit prefix, `.claude/meta/adr/NNN-slug.md`). That convention is governed by the ADR authoring practice; #10 pins the directory only.
- Changing the `## Document Templates` "you decide where to place" guidance without the architect's decision. How and whether to amend that section is a structural question delegated to Risk R-01.
- Specifying directory conventions for derived projects. Forks choose their own layout; this convention applies to this repository's dogfooding posture.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| product-manager (agent) | Authors Spec files at milestone pickup | Know the exact directory to use (`specs/`) without consulting prior examples or reading an additional file |
| architect (agent) | Authors ADR files after structural decisions | Know the exact directory to use (`.claude/meta/adr/`) without consulting prior examples |
| template maintainer (human) | Maintains the Roadmap and Spec/ADR inventory | Find the directory convention in a single, declared location citable in code review |
| template adopter | Forks the template into a derived project | Understand which conventions are this repo's pinned choices versus free-choice guidance for forks |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| product-manager | Know the canonical directory for a new Spec at milestone pickup | I place the file correctly on the first try without checking prior Spec paths for directory hints |
| architect | Know the canonical directory for a new ADR after a structural decision | I place the file correctly on the first try without checking prior ADR paths for directory hints |
| template maintainer | Find both directory conventions stated explicitly in a normative location | I can cite the rule in code review when a contributed Spec or ADR is placed in a non-canonical directory |
| template adopter | Know which parts of the layout are this repo's pinned choices | I can distinguish the template's dogfooding conventions from free-choice guidance I may override in my fork |

## Acceptance criteria

- **Given** a new Spec is being authored for any Roadmap row **when** `product-manager` chooses a directory **then** the canonical directory is `specs/` at the repository root, matching the reserved `spec:` path format already established by ADR-014 and #09.
- **Given** a new ADR is being authored after a structural decision **when** `architect` chooses a directory **then** the canonical directory is `.claude/meta/adr/` at the repository root, using a three-digit zero-padded prefix consistent with all existing ADRs.
- **Given** a bilingual project requirement for JA parity **when** both the EN Spec and its JA sibling are placed **then** both live in the **same** `specs/` directory as `specs/NN-slug.md` and `specs/NN-slug.ja.md` respectively — the directory does not split by language (no `specs/en/` or `specs/ja/` subdirectory is used in this repo's convention). <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
- **Given** the `## Document Templates` section's `adr/en/` and `adr/ja/` example **when** a template adopter reads it **then** it is clearly framed as an illustrative example for forks, not the pinned convention for this repository (the exact framing is deferred to the architect; see Risk R-01). <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- **Given** the stated directory conventions **when** documented in the location determined by the architect's decision **then** an agent executing the Spec-authoring or ADR-authoring step encounters both directory conventions without reading any additional file beyond what those steps already require (the exact location is deferred to the architect; see Risk R-01). <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- **Given** all existing Spec files (`specs/01-*.md` through `specs/09-*.md` plus `.ja.md` siblings) **when** the stated directory convention is applied retroactively **then** all are conformant — confirming this is a convention-statement milestone, not a bulk-move milestone.
- **Given** all existing ADR files (`.claude/meta/adr/001-*.md` through `.claude/meta/adr/018-*.md` plus `.ja.md` siblings) **when** the stated directory convention is applied retroactively **then** all are conformant.
- **Given** the MECE boundaries stated in this Spec **when** a future milestone author evaluates whether a new concern belongs in #10, #09, #04, #05, or #11 **then** the boundary is unambiguous: #04 validates path references in prose at commit time; #05 validates Roadmap glyph values and bidirectional ADR-link contracts at commit time; #09 governs the **filename** convention for Spec files (`NN-slug.md`); #10 governs the **directory location** where Spec and ADR files live (`specs/`, `.claude/meta/adr/`); #11 governs opt-in trigger guidance for verification domains. <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->

## Key interactions

1. **Interaction with milestone #09 (Spec filename convention).** #09 pins the filename form (`NN-slug.md`). #10 pins the directory (`specs/`). The two are MECE: together they specify the full canonical path `specs/NN-slug.md`. A future author uncertain about filename format reads #09; a future author uncertain about directory reads #10. Neither subsumes the other.
2. **Interaction with ADR-014 (Roadmap index as single entry point).** ADR-014's Spec reservation rule already implies the `specs/` directory via the `spec: specs/NN-slug.md` path in every Roadmap row. Milestone #10 makes the directory component of that reserved path normative by declaring it as an explicit convention. The reservation rule is unchanged; #10 adds a named rule that the reserved path's directory already satisfies.
3. **Interaction with milestone #04 (dangling-reference detector).** The #04 detector validates that path references in document prose resolve to existing files at commit time. If the architect's decision for #10 introduces a CI directory-conformance check, it is a distinct check from #04 in both trigger and scope: #04 checks whether a referenced path exists; a #10 CI check would check whether an existing file is placed in the canonical directory. The two are non-overlapping.
4. **Interaction with milestone #05 (Roadmap drift-detection CI).** The #05 detector validates Roadmap glyph well-formedness and bidirectional ADR-link contracts at commit time. A #10 CI check would validate `specs/` and `.claude/meta/adr/` directory contents, which is distinct from #05's scope. The two are non-overlapping.
5. **Interaction with milestone #06 (bilingual parity detector, ADR-018).** The #06 CI enforces heading-tree parity between EN and JA Spec files. #10's directory convention (EN and JA siblings coexist in `specs/`, not in `specs/en/` / `specs/ja/`) is a prerequisite for #06's per-file-pair keying to function correctly: #06 keys on `<stem>.ja.md` and derives `<stem>.md` from the same directory. If files were split across language subdirectories, #06's keying would break. #10 confirms the same-directory convention that #06 relies on. <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
6. **Interaction with `## Document Templates` guidance.** The `## Document Templates` section in CLAUDE.md currently says "you decide where to place the resulting documents" and provides a `adr/en/` / `adr/ja/` split as an illustrative bilingual example. This guidance is accurate for forks. The tension with #10's pinned-directory convention for this repo must be resolved by the architect's decision (see Risk R-01): either scope the "you decide" guidance explicitly to forks, or add a separate statement for this repo's pinned convention, or both. The reconciliation strategy is deferred; naming the tension is #10's contribution.
7. **Interaction with milestone #11 (opt-in trigger guidance for verification domains).** #11 is a reserved-but-absent Roadmap row. The MECE boundary between #10 and #11 is: #10 governs directory location for Spec/ADR files; #11 governs guidance for opt-in trigger behavior in verification domains — a non-overlapping concern. <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->
8. **Structural HOW deferred to architect.** Whether the directory convention is stated in CLAUDE.md (`## Document Templates` amended, `## Roadmap` Rules-block new bullet, or both), whether a CI directory-conformance check is warranted (new detector + new MECE partition + new keying ⇒ new ADR-019; consequence-clarification/extension of ADR-014's reservation-rule Decision ⇒ ADR-014 amendment — the architect applies the ADR-018 Alternative-B discriminator; ADR-018 is the latest consumed number, ADR-019 is unused), whether any agent prompt or the spec/adr templates require editing, and the exact MECE boundary documentation — all deferred to the architect's forthcoming decision. <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->

## Metrics

- **Leading:** After this milestone ships, every new Spec authored by `product-manager` is placed in `specs/` and every new ADR authored by `architect` is placed in `.claude/meta/adr/` without consulting prior file paths for directory hints — verifiable in session transcripts.
- **Leading:** Zero directory-placement deviations in `specs/` or `.claude/meta/adr/` from Roadmap row #10 forward, observable in git history.
- **Lagging:** Reduction in "where should I place this Spec/ADR?" questions in derived repos, as the conventions are stated explicitly in an inherited normative location.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — convention placement, `## Document Templates` tension, CI check, ADR strategy <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->

**Description.** This Spec states *what* the convention must cover (canonical directory for Specs, canonical directory for ADRs, same-directory bilingual convention, retroactive conformance) and the acceptance criteria for a conformant statement. It explicitly defers the structural *how*: where the directory convention is documented so agents encounter it at the authoring step without an additional file read; how the tension with `## Document Templates`'s "you decide" guidance is reconciled (scope it to forks? add a separate pinned-convention statement? amend the section?); whether a CI directory-conformance check is warranted and, if so, whether it is a new ADR-019 or an ADR-014 amendment (the architect applies the ADR-018 Alternative-B discriminator: new detector + new MECE boundary + new keying ⇒ new ADR-019; consequence-clarification/extension of ADR-014's existing reservation-rule Decision ⇒ ADR-014 amendment; ADR-018 is the latest consumed number, ADR-019 is unused); <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design --> and whether any agent prompt (product-manager.md, architect.md primarily) or the spec/adr templates require editing. This mirrors the R-01 pattern used by `specs/09-spec-filename-convention.md`, `specs/08-orchestrator-row-guard.md`, `specs/07-roadmap-status-transitions.md`, `specs/06-bilingual-parity-detector.md`, and `specs/05-roadmap-drift-detection-ci.md`.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) where the directory convention is documented so `product-manager` and `architect` encounter it at the authoring step without an additional file read (CLAUDE.md `## Document Templates` amendment vs `## Roadmap` Rules-block bullet vs both vs agent prompts), (b) how the tension between the "you decide where to place" guidance and the pinned convention is resolved — including whether the `## Document Templates` illustrative `adr/en/` / `adr/ja/` split example requires a scoping note clarifying it applies to forks not to this repo's pinned convention, (c) whether a CI directory-conformance check is included and, if so, whether it is an ADR-014 amendment or a new ADR-019 (applying the Alternative-B discriminator), (d) the explicit MECE boundary statement distinguishing #10's directory scope from #09's filename scope, #04's path-existence scope, #05's Roadmap structural scope, and any future #11 scope. <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation --> Until that decision exists, the implicit convention (inferred from the 27 existing conformant Spec and ADR files and the ADR-014 reservation rule) remains the operating practice, extended by this Spec's stated convention as process guidance.

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/10-spec-adr-directory-pinning.md`), following the precedent set by `specs/09-spec-filename-convention.md` for its architect decision. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Scope creep toward #09 (filename convention)

**Description.** Milestone #09 pins the filename form (`NN-slug.md`). A future author or reviewer may conflate "how the file is named" (#09) with "where the file lives" (#10). The adjacency is real: the full canonical path is `specs/NN-slug.md`, combining directory (#10's scope) and filename (#09's scope).

**Mitigation.** The MECE boundary is stated in the Non-goals, Goals, and Key interactions sections of this Spec. The acceptance criteria are scoped strictly to the directory component. If a future author proposes adding a filename rule to #10, the correct response is to route it to #09.

### Risk R-03: `## Document Templates` guidance tension

**Description.** The existing `## Document Templates` section's "you decide where to place" guidance is intentionally permissive for forks. Declaring a pinned convention for this repo in the same or adjacent location could confuse template adopters who expect to choose their own layout.

**Mitigation.** The architect's decision (Risk R-01, sub-point b) must explicitly address the scoping: either the pinned convention is stated with an explicit "for this repo's dogfooding posture" qualifier, or `## Document Templates` is amended to separate fork guidance from this-repo guidance, or both. The tension is named here so it cannot be resolved silently.

## Out of scope

- Renaming or moving any existing Spec file (`specs/01-*.md` through `specs/09-*.md`) — all are already in the canonical directory.
- Renaming or moving any existing ADR file (`.claude/meta/adr/001-*.md` through `.claude/meta/adr/018-*.md`) — all are already in the canonical directory.
- Changing the filename convention for Spec files — that is milestone #09.
- Adding a CI directory-conformance check — a structural decision deferred to the architect.
- Defining directory conventions for derived projects — forks choose their own layout per `## Document Templates` guidance.
- Changing the bilingual parity rule — #06 (ADR-018) owns that check.
- Changing the ADR three-digit prefix convention — that is the ADR authoring practice, not this milestone's scope.

## References

- ADR-014 (Roadmap index as single entry point) — §Decision "Milestone ↔ Spec is 1:1 and mandatory" and §Amendment (Spec reservation rule): the `spec: specs/NN-slug.md` path implies the `specs/` directory; #10 makes it normative as a named convention
- ADR-018 (Bilingual parity detector) — the CI that enforces heading-tree parity between EN and JA Spec files; its per-file-pair keying presupposes EN and JA siblings coexist in the same directory, which #10 confirms as the convention
- `specs/09-spec-filename-convention.md` — adjacent milestone: #09 pins the filename (`NN-slug.md`); #10 pins the directory (`specs/`); together they compose the full canonical path
- `specs/08-orchestrator-row-guard.md` — structural sibling; its R-01 establishes the ADR-018 Alternative-B discriminator instruction this Spec mirrors <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- `specs/07-roadmap-status-transitions.md` — structural sibling; its R-01 establishes the two-session decision-then-implementation split this Spec follows <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- `specs/05-roadmap-drift-detection-ci.md` — MECE boundary complement: #05 validates Roadmap structural integrity at commit time; #10 states the directory convention
- `specs/04-dangling-reference-detector.md` — MECE boundary complement: #04 validates path-reference existence in prose at commit time; #10 states directory location, not path existence
- `specs/11-verification-domain-opt-in-guidance.md` (reserved) — adjacent milestone: #11 governs opt-in trigger guidance for verification domains; #10 governs directory location for Spec/ADR files; the two are non-overlapping <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->
- Roadmap row: #10
