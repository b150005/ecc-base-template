# Spec Filename Convention Alignment (`NN-slug.md`)

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.10.0

## Problem

ADR-014's Spec reservation rule states that every Roadmap row carries a deterministic `spec:` link at row-creation time using the path `specs/NN-slug.md`. In practice, all eight Spec files authored to date (`specs/01-*.md` through `specs/08-*.md`) already follow this pattern — two-digit zero-padded row number, a kebab-case slug, the `.md` extension, and a `.ja.md` sibling for bilingual parity. The reservation rule therefore **implies** a filename convention, but that convention is never stated as a named, explicit rule.

The gap: no document declares the canonical form of `NN-slug.md` as an enforced requirement. Derived repos that fork this template have no pinned rule to inherit or enforce. Future milestone authors working on Roadmap rows #09–#100+ have no normative source to consult if they are uncertain about zero-padding, slug format, or the `.ja.md` sibling rule. The `specs/NN-progress.md` state files introduced by ADR-016 use the same `NN` prefix but serve a different lifecycle purpose — their relationship to the convention is also unstated.

The result is an implicit convention that works today by precedent but is invisible to new contributors and unenforceable by CI. Milestone #09 makes the convention explicit, stated, and normative without renaming any existing file.

## Goals

- Declare the canonical filename form for Spec files (`specs/NN-slug.md`, two-digit minimum zero-padded row number, kebab-case slug, `.md` extension) as an explicit, named convention in a normative location that agents and human contributors encounter during the Spec-authoring step.
- Extend the convention to cover the Japanese sibling (`specs/NN-slug.ja.md`) and its required heading-tree parity with the EN primary, formalizing what the bilingual parity CI (milestone #06) already enforces at the level of file existence and heading structure.
- State the relationship of `specs/NN-progress.md` (ADR-016 state files) to the convention: they share the `NN` prefix but are excluded from the `NN-slug.md` naming requirement because their lifecycle (created at session boundary, deleted at ◐→☑ flip) is governed entirely by ADR-016, not by this convention.
- Confirm that zero-padding to two digits covers Roadmap rows 01–99 and state the extension rule for rows 100+ so future authors do not independently invent it.
- Identify where the stated convention lives so it is encountered without reading an additional file beyond what the Spec-authoring step already requires (the exact placement is deferred to the architect; see Risk R-01).

## Non-goals

- Renaming any existing Spec file. All eight authored Spec files (`specs/01-*.md` through `specs/08-*.md`) already conform; no bulk-rename work is required or in scope.
- Changing the directory where Spec files live. Directory location is the subject of milestone #10 ("Spec/ADR directory location pin in CLAUDE.md") — a distinct, adjacent milestone. #09 is about the **filename** convention only; #10 is about the **directory** convention only. The two are MECE.
- Adding a new CI detector that mechanically checks filename conformance. Whether to add such a CI check is a structural decision deferred to the architect (see Risk R-01). #09 is a documentation/convention-statement milestone; CI enforcement is an optional consequence, not a deliverable of this milestone.
- Changing the Spec reservation rule. ADR-014's reservation rule (the Roadmap row carries the `spec:` path at row-creation time) is correct and unchanged. #09 makes the filename portion of that reserved path normative — it does not alter the reservation rule itself.
- Changing the heading-tree parity rule. Parity between EN and JA files is already enforced by the bilingual parity CI (milestone #06, ADR-018). #09 references that rule as already in force; it does not redefine or extend it.
- Specifying a naming convention for ADR files. ADR files use a three-digit zero-padded prefix (`001-`) under `.claude/meta/adr/`; their convention is fully governed by the ADR authoring practice and does not share a numbering namespace with Spec files.

## Target users

| Persona | Description | Primary Need |
|---------|-------------|--------------|
| product-manager (agent) | Authors Spec files at milestone pickup | Know the exact filename format to use (`specs/NN-slug.md`) and the rules for zero-padding, slug casing, and the JA sibling without consulting prior examples |
| template maintainer (human) | Maintains the Roadmap and Spec inventory | Find the filename convention in a single, declared location that can be cited in code review |
| template adopter | Forks the template into a derived project | Inherit an explicit filename convention rather than reversing it from prior examples |
| architect (agent) | Decides where the convention is documented and whether a CI check is warranted | Receive a well-scoped structural decision from the Spec: what to formalize, not how |

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| product-manager | Know the canonical filename form for a new Spec at the moment I pick up a milestone | I name the file correctly on the first try without checking prior Spec filenames for format hints |
| product-manager | Know the rule for the JA sibling filename and its parity requirement | I create the JA file correctly without consulting the bilingual parity detector's documentation separately |
| template maintainer | Find the filename convention stated explicitly in a normative location | I can cite the rule in code review when a contributed Spec uses the wrong format |
| template adopter | Inherit the convention when forking | My derived repo's Spec files are consistent from the first milestone without requiring me to discover the convention from examples |

## Acceptance criteria

- **Given** a new Spec is being authored for Roadmap row `NN` **when** `product-manager` names the file **then** the canonical form is `specs/NN-slug.md` where `NN` is the row number zero-padded to a minimum of two digits (01, 02, …, 09, 10, …, 99) and `slug` is a kebab-case summary of the milestone name, matching the slug used in the Roadmap row's reserved `spec:` path.
- **Given** the Roadmap row number reaches three digits (100+) **when** a new Spec is named **then** the number is written without additional padding (100, 101, …) — the two-digit minimum applies only to single-digit rows (1→01), not to rows that are already multi-digit.
- **Given** a bilingual project requiring JA parity **when** the EN Spec is created **then** the JA sibling is named `specs/NN-slug.ja.md` — same `NN` and `slug`, with `.ja` inserted before `.md` — and the JA file's heading tree has level-and-position parity with the EN file as enforced by the bilingual parity CI (milestone #06, ADR-018).
- **Given** a `specs/NN-progress.md` state file created by the ADR-016 cross-session persistence mechanism **when** evaluating whether it conforms to the `NN-slug.md` convention **then** it is explicitly excluded: progress files are named `NN-progress.md` by convention (where `NN` matches the in-progress Roadmap row) and their lifecycle is governed entirely by ADR-016; they are not Spec files and do not require a kebab-case slug suffix other than `progress`.
- **Given** the stated convention **when** documented in the location determined by the architect's decision **then** an agent executing the Spec-authoring step encounters the convention without reading any additional file beyond what that step already requires (the exact location is deferred to the architect; see Risk R-01). <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation -->
- **Given** the eight existing Spec files (`specs/01-*.md` through `specs/08-*.md`) **when** the stated convention is applied retroactively **then** all eight are conformant — confirming this is a convention-statement milestone, not a bulk-rename milestone.
- **Given** the MECE boundaries stated in this Spec **when** a future milestone author evaluates whether a new concern belongs in #09, #04, #05, or #10 **then** the boundary is unambiguous: #04 validates path references in prose at commit time; #05 validates Roadmap glyph values and bidirectional ADR-link contracts at commit time; #09 is about the **filename** convention for Spec files; #10 is about the **directory location** where Spec and ADR files live.

## Key interactions

1. **Interaction with ADR-014 Spec reservation rule.** ADR-014 requires every Roadmap row to carry a deterministic `spec:` link at row-creation time using the path `specs/NN-slug.md`. Milestone #09 makes the filename component of that reserved path normative by declaring it as an explicit convention. The reservation rule is unchanged; #09 adds a named rule that the reserved path's filename already satisfies.
2. **Interaction with milestone #10 (Spec/ADR directory location pin).** #10 pins the directory where Spec and ADR files live (`specs/`, `.claude/meta/adr/`). #09 pins the filename format within the `specs/` directory. The two milestones are MECE: #09 governs filename; #10 governs directory. Neither subsumes the other. A future author uncertain about directory location reads #10; a future author uncertain about filename format reads #09.
3. **Interaction with milestone #04 (dangling-reference detector).** The #04 detector validates that path references in document prose resolve to existing files at commit time. If the architect's decision for #09 introduces a CI filename-format check, it is a distinct check from #04 in both trigger and scope: #04 checks whether a referenced path exists; a #09 CI check would check whether an existing filename conforms to the format. The two are non-overlapping.
4. **Interaction with milestone #05 (Roadmap drift-detection CI).** The #05 detector validates Roadmap glyph well-formedness and bidirectional ADR-link contracts at commit time. If the architect's decision for #09 introduces a CI filename-format check, it is distinct from #05 in scope: #05 validates the Roadmap table's structural integrity; a #09 CI check would validate `specs/` directory contents. The two are non-overlapping.
5. **Interaction with milestone #06 (bilingual parity detector, ADR-018).** The #06 CI already enforces heading-level and heading-position parity between EN and JA Spec files. The JA sibling naming rule (`NN-slug.ja.md`) stated in this Spec's acceptance criteria is complementary: #06 enforces structural parity of file content; #09's convention enforces the filename form of the sibling. Both must hold for a conformant bilingual Spec.
6. **Interaction with ADR-016 (cross-session progress persistence).** ADR-016 defines `specs/NN-progress.md` as the state carrier for ◐ in-progress milestones. These files share the `specs/` directory with Spec files and use the same `NN` prefix. This Spec explicitly excludes them from the `NN-slug.md` convention, confirming that `progress` is a reserved slug suffix under ADR-016's lifecycle and not a general-purpose kebab-case slug.
7. **Structural HOW deferred to architect.** Whether the convention is stated in CLAUDE.md (Roadmap Rules block, a new "Spec filename convention" bullet, or the `product-manager` agent prompt), in the spec-template's `## How to use this template` block, or as a combination; whether a CI filename-format check is warranted (new detector + new MECE boundary ⇒ new ADR-019, or consequence-clarification of ADR-014's reservation rule ⇒ ADR-014 amendment — the architect applies the ADR-018 Alternative-B discriminator); and the exact MECE boundary documentation — all deferred to the architect's forthcoming decision. <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation -->

## Metrics

- **Leading:** After this milestone ships, every new Spec authored by `product-manager` uses the `NN-slug.md` form without consulting prior Spec filenames for format hints — verifiable in session transcripts.
- **Leading:** Zero filename-format deviations in `specs/` from Roadmap row #09 forward, observable in git history.
- **Lagging:** Reduction in "what should I name this Spec?" questions in derived repos, as the convention is stated explicitly in an inherited normative location.

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — convention placement, CI check, ADR strategy <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation -->

**Description.** This Spec states *what* the convention must cover (canonical form, zero-padding rule, JA sibling form, progress-file exclusion, 100+ extension rule) and the acceptance criteria for a conformant statement. It explicitly defers the structural *how*: where the convention is documented so agents encounter it at the Spec-authoring step without an additional file read; whether a CI filename-format check is warranted and, if so, whether it is a new ADR-019 or an ADR-014 amendment (the architect applies the ADR-018 Alternative-B discriminator: new detector + new MECE boundary + new keying ⇒ new ADR-019; consequence-clarification/extension of ADR-014's existing reservation-rule Decision ⇒ ADR-014 amendment; ADR-018 is the latest consumed number, ADR-019 is unused); <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation --> and whether any agent prompt (product-manager.md primarily) requires editing. This mirrors the R-01 pattern used by `specs/08-orchestrator-row-guard.md`, `specs/07-roadmap-status-transitions.md`, `specs/06-bilingual-parity-detector.md`, and `specs/05-roadmap-drift-detection-ci.md`.

**Mitigation constraint handed to architect.** The architect's forthcoming decision must specify: (a) where the convention is documented so `product-manager` encounters it at the Spec-authoring step without an additional file read, (b) whether a CI filename-format check is included and, if so, whether it is an ADR-014 amendment or a new ADR-019 (applying the Alternative-B discriminator), (c) whether product-manager.md or the spec-template requires editing and which sections are affected, and (d) the explicit MECE boundary statement distinguishing #09's filename scope from #10's directory scope, #04's path-existence scope, and #05's Roadmap structural scope. <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation --> Until that decision exists, the implicit convention (inferred from the eight existing conformant Spec files and the ADR-014 reservation rule) remains the operating practice, extended by this Spec's stated convention as process guidance.

**Note:** The `<!-- ref-allow: -->` suppressions on lines referencing the forthcoming architect decision live only in this Spec file (`specs/09-spec-filename-convention.md`), following the precedent set by `specs/08-orchestrator-row-guard.md` for its architect decision, `specs/07-roadmap-status-transitions.md` for its architect decision, `specs/05-roadmap-drift-detection-ci.md` for ADR-017, and `specs/06-bilingual-parity-detector.md` for ADR-018. They do NOT appear in `CLAUDE.md`.

### Risk R-02: Scope creep toward #10 (directory location)

**Description.** Milestone #10 pins the directory where Spec and ADR files live. A future author or reviewer may conflate "where the file lives" (#10) with "how the file is named" (#09). The adjacency is real: the full canonical path is `specs/NN-slug.md`, which combines the directory (#10's scope) and the filename (#09's scope).

**Mitigation.** The MECE boundary is stated in the Non-goals, Goals, and Key interactions sections of this Spec. The acceptance criteria are scoped strictly to the filename component. The architect's decision should repeat the boundary in the convention's placement documentation. If a future author proposes adding a directory rule to #09, the correct response is to route it to #10.

### Risk R-03: Ambiguity of "slug" definition

**Description.** "Kebab-case slug" is a commonly understood term but not formally defined here. A future author might produce `09-spec-filename-convention-alignment-nn-slug-md.md` (over-long) or `09-sfca.md` (opaque abbreviation) or `09-Spec_Filename.md` (wrong casing).

**Mitigation.** The acceptance criteria state "kebab-case summary of the milestone name, matching the slug used in the Roadmap row's reserved `spec:` path." Because the slug is fixed at row-creation time when the Roadmap row's `spec:` link is reserved, there is no authoring ambiguity at pickup time: `product-manager` reads the reserved path from the Roadmap row and uses that slug exactly. The risk is reduced to row-creation time, where the architect's decision may add a slug-length or format constraint if warranted.

## Out of scope

- Renaming any existing Spec file (`specs/01-*.md` through `specs/08-*.md`) — all are already conformant.
- Changing the directory where Spec files live — that is milestone #10.
- Adding a CI filename-format check — a structural decision deferred to the architect.
- Changing the ADR filename convention (`.claude/meta/adr/NNN-slug.md` with three-digit prefix) — ADR files use a separate namespace and convention.
- Translating the convention statement to derived-repo documentation — a technical-writer task in derived repos when they fork.
- Enforcing JA heading-tree parity beyond what milestone #06 already enforces — #06 owns that check.

## References

- ADR-014 (Roadmap index as single entry point) — §Decision "Milestone ↔ Spec is 1:1 and mandatory" and §Amendment (Spec reservation rule): the `specs/NN-slug.md` path is already implied by the reservation rule; #09 makes it normative as a named convention
- ADR-016 (Cross-session progress persistence) — defines `specs/NN-progress.md` as the state carrier for ◐ rows; #09 excludes progress files from the `NN-slug.md` convention and confirms `progress` as a reserved suffix under ADR-016
- ADR-018 (Bilingual parity detector) — the CI that already enforces heading-tree parity between EN and JA Spec files; #09 references its enforcement scope without redefining it
- `specs/08-orchestrator-row-guard.md` — structural sibling; its R-01 establishes the forward-reference pattern and the ADR-018 Alternative-B discriminator instruction this Spec mirrors <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation -->
- `specs/07-roadmap-status-transitions.md` — structural sibling; its R-01 establishes the two-session decision-then-implementation split this Spec follows <!-- ref-allow: forthcoming architect decision for #09; authored when #09 moves to implementation -->
- `specs/05-roadmap-drift-detection-ci.md` — MECE boundary complement: #05 validates Roadmap structural integrity at commit time; #09 states the filename convention within `specs/`
- `specs/04-dangling-reference-detector.md` — MECE boundary complement: #04 validates path-reference existence in prose at commit time; #09 states filename format, not path existence
- `specs/10-spec-adr-directory-pinning.md` (reserved) — adjacent milestone: #10 pins the directory; #09 pins the filename; the two are MECE and together specify the full canonical path <!-- ref-allow: #10 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->
- Roadmap row: #09
