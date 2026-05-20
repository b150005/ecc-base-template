# Commit `compliance.yml` as Active Default

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap row #20

## Problem

The template ships `.claude/compliance.yml.example` but no committed
`.claude/compliance.yml`. A fork that clones the template and immediately
begins work that involves legal-exposure capabilities (chat, payments, PII
collection, data export) has no compliance Skill activation — even if the
fork maintainer read ADR-011 and intended to use the Skill. The `.example`
suffix signals "copy this eventually" rather than "this is ready to activate
now." The actual copy step is easy to omit because there is no visible failure
when it is skipped and no prompt to perform it.

ADR-011 §Decision explicitly chose `default-off` with the stated rationale:
"Forces every fork to declare jurisdictions before any session can run, even
forks that have nothing to do with end-user releases" → "Default-off respects
the template's role; opt-in is one config line." This was sound at ADR-011
authoring time. However, the parallel milestone #19 (workaround tracking) has
confirmed a template-level convention: once a CI/config scaffold is stable and
its default state is known safe for a zero-activity project, it ships
committed — not as an `.example` — so fork maintainers get real coverage
without a manual copy step.

The compliance case carries a critical differentiator from workaround tracking:
ADR-011 Invariant 5 ("Project-declared jurisdictions, never guessed") means the
template **cannot** legitimately commit a `.claude/compliance.yml` with
`enabled: true` and a populated `target_jurisdictions:` list on behalf of
forks. That would be the template guessing which legal jurisdictions apply —
exactly what Invariant 5 prohibits. The `.example` file ships with `JP`
uncommented, which is appropriate as an illustrative default, but the committed
file must not assert that all forks operate under Japanese law.

Milestone #20 therefore evaluates whether committing `.claude/compliance.yml`
with `enabled: false` (and `target_jurisdictions:` as a clearly documented
opt-in step the maintainer asserts) achieves meaningful fork-time improvement
without violating Invariant 5 — and delivers whichever outcome the architect's
design decision (new ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> or ADR-011 amendment) determines is
correct.

## Goals

- The template ships `.claude/compliance.yml` committed and tracked by git,
  eliminating the manual copy step for fork maintainers who wish to use the
  compliance Skill.
- Fork maintainers who enable the Skill face a single, clearly documented
  assertion step (`target_jurisdictions:`) rather than also having to locate
  and copy an `.example` file.
- The compliance Skill's six invariants are unimpaired by this milestone;
  in particular, Invariant 5 (no jurisdiction guessing) is enforced by the
  committed file's own comments.
- The `.claude/compliance.yml.example` is retained as a fully-annotated
  reference alongside the committed active config.
- All seven canonical detectors and their eight test suites pass with
  EXIT=0 after this milestone's changes land.

## Non-goals

- **Implementation mechanism is deferred to ADR-023.** <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> Whether this milestone
  is achieved by committing a new `.claude/compliance.yml` file with
  `enabled: false`, by amending ADR-011's §Decision "default-off" language,
  by issuing a superseding ADR-023, or by a different structural approach is <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  an architect decision. The Spec defines observable outcomes only.
- **No populated `target_jurisdictions:` in the committed file.** The
  compliance Skill's Invariant 5 prohibits the template from asserting which
  legal jurisdictions apply to any given fork. The committed `.claude/compliance.yml`
  must document the declaration requirement; it must not pre-populate
  jurisdictions on behalf of forks. This is the central differentiator from
  milestone #19 (workaround tracking, which has no analogous operator-assertion
  barrier).
- **No `enabled: true` in the committed file without operator assertion.**
  Activating the compliance Skill requires the fork maintainer to declare
  `target_jurisdictions:`. Committing `enabled: true` without a populated list
  would cause the Skill to refuse-to-run on every session start, which is
  actively worse than the current state. Whether `enabled: false` or
  `enabled: true` (with a structured operator-assertion workflow) is correct
  is an architect decision, not this Spec's.
- **No amendment to ADR-011's six invariants by this Spec.** Whether any
  invariant wording changes is resolved by ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> or an ADR-011 amendment.
  This Spec makes no prejudgment.
- **No modification to the compliance Skill's `SKILL.md` at Spec-authoring
  time.** If Invariant 4 ("Default-off, opt-in per project") wording requires
  updating to reflect the post-#20 state, that is part of ADR-023's design <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  scope and is implemented at step 5, not during Spec authoring.
- **No update to `.claude/CLAUDE.md` §6a section text at Spec-authoring
  time.** That section's "default-off" language may require updating to reflect
  the post-#20 state. Whether and how that text changes is part of
  ADR-023's design scope <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> and is implemented by the technical-writer at
  step 7, not during Spec authoring.
- **MECE with #19 and #21.** #19 owned the workaround-tracker default-on
  transition (`.github/workaround-tracker.yml`); #20 owns the compliance
  config commitment (`.claude/compliance.yml`); #21 owns the quality-gate loop
  re-entry anchor (Roadmap row). These three milestones are structurally related
  but non-overlapping: implementation of one does not constitute implementation
  of the others.
- **No CHANGELOG edit at Spec-authoring time.** The technical-writer adds the
  CHANGELOG entry at step 7 of the development workflow, not during Spec
  authoring.
- **No JA sibling authored by this Spec.** `specs/20-ship-compliance-yml-committed.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  is authored by the technical-writer at step 7. Its heading-tree parity is
  governed by Roadmap #06.

## User stories

| As a...                          | I want to...                                                                              | So that...                                                                                                                                   |
|----------------------------------|-------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| fork maintainer (compliance-aware) | find `.claude/compliance.yml` committed in the template at fork time                   | I can enable the compliance Skill by editing one already-present file rather than copying an `.example`                                     |
| fork maintainer (not compliance-aware) | leave the committed `.claude/compliance.yml` at its default state               | the compliance Skill remains inactive and I incur zero noise without knowing it exists                                                       |
| security-reviewer                | verify that the committed file's comments make the jurisdiction-assertion requirement clear | I can confirm that Invariant 5 is documented at the config layer without reading ADR-011                                                    |
| template maintainer              | confirm that a fresh fork with the committed file produces zero Skill-activation noise    | I can confidently ship the committed config without risking spurious compliance output in forks that have not declared jurisdictions           |

## Acceptance criteria

- **AC-1 — `.claude/compliance.yml` present and committed in template:**
  Given the post-#20 template, when a fork is created without any manual
  setup step, then `.claude/compliance.yml` exists at that path and is
  tracked by git. The fork maintainer does not need to copy the `.example`
  file to proceed.

- **AC-2 — Invariant 5 documented at config layer:**
  Given the committed `.claude/compliance.yml`, when a fork maintainer
  reads the file, then the `target_jurisdictions:` field carries inline
  comments that explain (a) the operator-assertion requirement and (b) the
  fact that the Skill refuses to run if the list is empty or absent. The
  file must not pre-populate any jurisdiction code on behalf of forks.

- **AC-3 — Zero Skill-activation noise on default committed state:**
  Given a fork with the committed `.claude/compliance.yml` at its default
  state (no jurisdictions declared), when an agent session runs and a
  capability-detection trigger fires, then the compliance Skill either
  (a) does not activate (if `enabled: false` in the committed file) or
  (b) emits a single-line refusal asking the operator to declare
  jurisdictions (if `enabled: true` but `target_jurisdictions:` is empty).
  In neither case does it produce a compliance checklist against guessed
  jurisdictions. The exact mechanism is decided by ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->

- **AC-4 — `.claude/compliance.yml.example` retained:**
  Given the post-#20 commit, when `ls .claude/compliance.yml.example` is
  run, then the file exists. The `.example` retains all fully-annotated
  fields (including commented-out jurisdictions, `operator_attestations`,
  and `reverification_days`) and is clearly labeled in its header comment
  as documentation-only, not the active config.

- **AC-5 — ADR-011 consistency is addressed in writing:**
  Given the potential tension between this milestone and ADR-011 §Decision
  ("ships default-off … created on opt-in; absent by default"), when the
  architect completes the design step, then either (a) a new ADR-023 <!-- ref-allow: counterfactual reference in OR-condition; architect may choose path (a) ADR-023 or (b) ADR-011 amendment | expires: 2026-06-20 --> exists
  and explicitly addresses whether ADR-011 §Decision's "absent by default"
  clause is upheld, amended, or superseded, recording the rationale; or
  (b) ADR-011 itself receives an amendment that explicitly addresses this
  clause (upheld / amended / superseded) and records the rationale. The
  Spec does not prescribe which path the architect takes; AC-5 is satisfied
  when either (a) or (b) exists on disk and contains that resolution. The
  architect applies the ADR-018 Alternative-B triad discriminator to decide
  between paths.

- **AC-6 — Six compliance Skill invariants preserved:**
  Given the committed `.claude/compliance.yml` and the compliance Skill's
  `SKILL.md`, when the Skill is invoked on a fork that has declared
  `target_jurisdictions:` and set `enabled: true`, then all six invariants
  (no negative-applicability claims; primary-source citation only;
  PII-path refusal; default-off per Skill internal logic; project-declared
  jurisdictions required; capability-detection not name-matching) remain
  intact and unimpaired. This milestone does not weaken any invariant.

- **AC-7 — Seven canonical detectors all EXIT=0:**
  Given the seven canonical detectors (`check-bilingual-parity.sh`,
  `check-dangling-refs.sh`, `check-ecc-delegation-consistency.sh`,
  `check-roadmap-drift.sh`, `check-ref-allow-expiry.sh`,
  `check-research-tier-auth.sh`, `check-skill-invariants.sh`), when each
  is run against the post-#20 repository state, then all seven exit with
  code 0. If this milestone introduces an eighth detector, the Spec
  accommodates it and AC-7 extends to include it.

- **AC-8 — Eight canonical test suites all pass:**
  Given the eight canonical test suites (`test-check-bilingual-parity.sh`,
  `test-check-dangling-refs.sh`, `test-check-ecc-delegation-consistency.sh`,
  `test-check-ref-allow-expiry.sh`, `test-check-roadmap-drift.sh`,
  `test-check-research-tier-auth.sh`, `test-check-skill-invariants.sh`,
  and the CI base runner), when each is run against the post-#20 repository
  state, then all eight pass without modification to existing test logic.
  If this milestone introduces a ninth test suite, AC-8 extends to include it.

- **AC-9 — Roadmap row #20 reflects ship state:** <!-- ref-allow: .claude/meta/adr/023-*.md is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  Given the post-#20 commit, when `.claude/CLAUDE.md` is read, then
  Roadmap row #20 shows `☑ done`, the `spec:` link resolves to
  `specs/20-ship-compliance-yml-committed.md`, and if ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> was issued,
  the `adr:` link resolves to `.claude/meta/adr/023-*.md`.

- **AC-10 — CHANGELOG entry present:**
  Given the post-#20 state after step 7, when `CHANGELOG.md` is read,
  then a `### Changed` or `### Added` entry under `## [Unreleased]` records
  the compliance config commitment. The technical-writer authors this entry
  at step 7.

- **AC-11 — JA sibling heading-tree parity:**
  Given the post-#20 state after step 7, when `specs/20-ship-compliance-yml-committed.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  is read, then its heading tree matches the EN Spec's heading tree exactly
  (per Roadmap #06 parity ownership). The technical-writer authors this file
  at step 7.

## Key interactions

- **product-manager:** Authors this Spec (current step). Flips Roadmap #20
  from `☐ todo` to `◐ in-progress` atomically with Spec authoring.
- **architect:** Applies the ADR-018 Alternative-B triad discriminator
  (new contract boundary — committed file vs. absent file; same
  keying/mechanism — single config toggle; structural question — whether
  the "absent by default" clause in ADR-011 §Decision needs formal revision)
  to determine whether ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> is warranted or ADR-011 receives an amendment.
  The architect's decision governs AC-3 and AC-5. If ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> is issued,
  the architect adds the `adr:` link to Roadmap row #20.
- **implementer:** Treats each AC as a verbatim contract. Commits
  `.claude/compliance.yml` per the mechanism directed by ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> Does not
  pre-populate `target_jurisdictions:` on behalf of forks (AC-2). Verifies
  AC-3 (zero noise) against a fork with the default config state. Runs all
  canonical detectors and test suites to verify AC-7 and AC-8.
- **code-reviewer:** Verifies AC-2 (Invariant 5 documented at config layer),
  AC-3 (zero noise on default state), AC-4 (`.example` retained), and
  AC-6 (six invariants preserved) independently against real files.
- **technical-writer:** At step 7 — (a) adds one CHANGELOG entry (AC-10);
  (b) authors `specs/20-ship-compliance-yml-committed.ja.md` (AC-11); <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  (c) reviews whether §6a in `.claude/CLAUDE.md` ("default-off" language)
  requires updating to match the post-#20 state, and if so, updates it
  (this edit is in scope at step 7, not during Spec authoring).

## Metrics

- **Leading:** EXIT=0 from all seven (or eight) canonical detectors after
  implementation, measured via the `make check` or equivalent CI run.
  Immediately verifiable at implementation time.
- **Leading:** All eight (or nine) canonical test suites pass without
  modification to existing test logic. Measurable at implementation time.
- **Lagging:** Reduction in newly forked projects that lack a compliance
  config file after week one (qualitative observation). The expectation is
  that a committed file eliminates the "forgot to copy the `.example`" class
  of failures entirely in forks that intend to use the compliance Skill.

## Risks and open questions

- **ADR-011 §Decision "absent by default" tension.** ADR-011 §Neutral
  Consequences states: "A new config file `.claude/compliance.yml` joins
  `.claude/verification.yml.example` as a domain-specific opt-in config.
  The two files are siblings, both default-off, both single toggles." The
  parallel `verification.yml` is no longer absent — it shipped committed
  via milestone #01. If the symmetry argument holds, committing
  `compliance.yml` with `enabled: false` is consistent. However, ADR-011
  explicitly chose to keep the compliance config "absent by default" (not
  merely "disabled by default"), and that choice appears in §Decision, not
  just §Consequences. The architect's ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> or ADR-011 amendment must
  address whether "absent" vs. "committed but disabled" is a meaningful
  distinction at the safety level or a purely procedural one. This is the
  primary open question for ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- **Invariant 4 wording in `SKILL.md`.** The SKILL.md currently states:
  "This Skill ships **default-off**." If the committed file moves from
  "absent" to "committed with `enabled: false`", the invariant text may be
  accurate (the Skill is still default-off) or may need qualification.
  The architect will determine whether this requires a SKILL.md edit.
- **Jurisdiction ambiguity in the `.example`.** The `.example` file ships
  with `JP` uncommented in `target_jurisdictions:`. If a fork maintainer
  copies the committed file to a second location by accident and activates
  it without reading the comments, they may inadvertently declare JP
  jurisdiction. The committed file's inline comments and the technical-writer's
  CHANGELOG entry should make the operator-assertion requirement explicit.
  This is a documentation risk, not a Skill safety risk (Invariant 5 still
  prevents the Skill from running on an empty list).
- **Fork update path.** Projects that forked the template before #20 will
  not automatically receive the committed file. The CHANGELOG entry should
  note that existing forks can adopt the committed file by pulling the
  upstream change or by manually copying `.claude/compliance.yml.example`
  to `.claude/compliance.yml`.

## Out of scope

- ADR-011 §Decision "absent by default" amendment or supersession
  (architect, via ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> or ADR-011 amendment).
- Populating `target_jurisdictions:` in the committed file on behalf of forks
  (prohibited by Invariant 5; belongs to each fork's operator assertion).
- Modifying any of the six compliance Skill invariants (SKILL.md is read-only
  for this milestone; architect governs any invariant change).
- Adding new jurisdictions to the Skill's MVP set (JP, EU, US-CA, platform)
  — vertical-specific regimes remain delegated to ECC Skills.
- CHANGELOG edit at Spec-authoring time (technical-writer at step 7).
- JA sibling authoring at Spec-authoring time (technical-writer at step 7).
- `.claude/CLAUDE.md` §6a section text update at Spec-authoring time
  (technical-writer at step 7, conditional on ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> outcome).
- #19 ("Workaround tracking default-on") — completed; MECE boundary noted
  in Non-goals.
- #21 ("Quality-gate loop re-entry anchored to Roadmap row") — separate
  milestone; MECE boundary noted in Non-goals.

## References

- Roadmap row: #20
- `.claude/meta/adr/011-compliance-checklist-skill.md` — ADR-011; §Decision
  "absent by default" clause and "Make the Skill default-on" rejected
  alternative are the primary tension this milestone resolves via ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- `.claude/compliance.yml.example` — current source of the active config
  content; retained as documentation-only reference (AC-4)
- `.claude/skills/compliance-checklist/SKILL.md` — six invariants; Invariant 5
  (jurisdiction declaration required, never guessed) is the central constraint
  governing AC-2 and AC-3
- `specs/01-ship-verification-yml-committed.md` — precedent for committing a
  config scaffold that was previously `.example`-only (milestone #01)
- `specs/19-workaround-tracking-default-on.md` — structural parallel for
  default-on transition; MECE boundary noted in Non-goals. The OR-condition
  pattern for AC-5 mirrors this Spec's AC-5 exactly
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Spec
  reservation rule and 1:1 milestone↔Spec mapping
