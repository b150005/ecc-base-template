# CI Exemption Allowlist Expiry/Review Mechanism

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap row #18

## Problem

The template ships six distinct exemption mechanisms that allow CI detectors
and test suites to suppress false positives. These mechanisms serve legitimate
purposes: forwarding references to files not yet authored, structurally computed
carve-outs for opt-in vocabulary, absence-of-claim conventions, and grandfather
rules for pre-existing artifacts. However, none of these mechanisms carries any
notion of expiry, review cadence, responsible owner, or re-evaluation trigger.
A `<!-- ref-allow: <reason> -->` marker added to suppress a genuine forward
reference during a milestone's implementation window silently persists long after
the referenced artifact has been created, becoming an over-suppression that hides
new dangling references behind the same line. Roadmap milestones #16 and #17
both required ad-hoc per-line adjudication by the technical-writer to remove
ref-allow markers that had become over-suppressions once their target files
materialized. This pattern is structural, not incidental: every ref-allow marker
added today has no mechanism to prompt re-evaluation tomorrow. The template
needs a lifecycle mechanism for exemptions so that the exemption corpus does not
silently accumulate stale suppressions that defeat the purpose of the detectors.

## Goals

- Introduce an expiry concept for `<!-- ref-allow: <reason> -->` markers so that
  time-bounded exemptions can be distinguished from permanent structural ones.
- Enable CI to detect expired ref-allow markers and produce a WARN signal (not a
  hard FAIL), prompting human re-evaluation without breaking existing pipelines.
- Define review-cadence ownership for expired and long-lived ref-allow markers
  (template maintainer for template-internal markers; fork maintainer for
  derived-repo markers).
- Establish a grandfather rule that exempts all ref-allow markers present in
  the repository at the time this milestone ships from the new expiry requirement
  — no breaking change to existing suppressions.
- Clarify the MECE boundary between this milestone (#18) and the artifact-self-keyed
  exemption mechanisms (skill-invariants grandfather, ADR-017 absence-of-claim,
  ADR-014 Reservation-rule carve-out), which are explicitly out of scope.

## Non-goals

- **No path allowlist.** This milestone does not create a centralized allowlist
  file of exempted paths. ADR-015 amendment explicitly anti-pattern-classifies
  path allowlists as prone to staleness and inconsistency with structural keying.
  The ref-allow mechanism remains line-level.
- **No lifecycle change to artifact-self-keyed exemptions.** The three
  structurally computed exemptions — the skill-invariants `is_exempt()` grandfather
  in `check-skill-invariants.sh`, the ADR-017 absence-of-claim exemption in
  `check-roadmap-drift.sh`, and the ADR-014 Reservation-rule carve-out in
  `check-dangling-refs.sh` — are keyed on the artifact's own structure, not on
  a human-authored reason string. Their staleness risk is qualitatively different
  from ref-allow markers; lifecycle changes for these three are a separate future
  milestone.
- **No modification to `workaround-tracker.yml` expiry machinery.** The existing
  `expires_on` and `expiry_warning_days` fields in `.github/workaround-tracker.yml`
  govern upstream-workaround registry entries, not CI exemption markers. This
  milestone does not alter that mechanism. It serves as a prior-art reference only.
- **No modification to the ADR-015 amendment vocabulary carve-out.** The
  `absent` / `default-off` / `opt-in` vocabulary keying and `.example` sibling
  structural signal in `check-dangling-refs.sh` is structurally computed, not a
  ref-allow string. It is out of scope.
- **No hard FAIL on expired markers.** Expired markers produce a WARN signal, not
  a pipeline-blocking FAIL. This mirrors the grace-period philosophy introduced
  by the ADR-015 amendment (WARN-not-FAIL for vocabulary carve-out edge cases)
  and avoids breaking derived repositories that have not yet upgraded.
- **No new CI detector authored by this Spec.** The concrete implementation
  mechanism (amendment to existing detectors, a new seventh detector, or a
  separate check) is deferred to the architect. This Spec defines what must be
  detectable; the ADR defines how.
- **MECE with #16 and #17.** Roadmap #16 owned the ADR-001 Status vocabulary
  correction; #17 owned the ADR-002/003/004 Status format normalization and
  CHANGELOG sync. #18 owns the CI exemption lifecycle mechanism. These three
  milestones are non-overlapping.
- **No CHANGELOG edit at Spec-authoring time.** The technical-writer adds the
  CHANGELOG entry at step 7 of the development workflow, not during Spec
  authoring.
- **No JA sibling authored by this Spec.** `specs/18-ci-exemption-allowlist-expiry.ja.md`
  is authored by the technical-writer at step 7. Its heading-tree parity is
  governed by Roadmap #06.

## User stories

| As a...                             | I want to...                                                         | So that...                                                                               |
|-------------------------------------|----------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| template maintainer                 | add a time-bounded ref-allow marker with an expiry date              | CI reminds me to re-evaluate the suppression once the referenced artifact should exist   |
| fork maintainer                     | see a WARN (not FAIL) when a ref-allow marker in my repo has expired | I know which suppressions to review without my pipeline breaking unexpectedly            |
| implementer authoring a Spec        | write ref-allow markers using the existing syntax for grandfather cases | my existing markers are not invalidated by the new mechanism                           |
| code-reviewer validating a milestone | verify that all new ref-allow markers either carry an expiry date or are explicitly grandfathered | the exemption corpus does not grow without accountability |

## Acceptance criteria

- **AC-1 — Expiry date format defined:**
  Given a ref-allow marker with an expiry date, when CI processes the line,
  then the date must conform to ISO 8601 (`YYYY-MM-DD`); any other format
  is treated as absent (no expiry).

- **AC-2 — Extended ref-allow syntax:**
  Given the existing `<!-- ref-allow: <reason> -->` syntax, when this
  milestone ships, then an optional expiry clause is supported in the form
  `<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->`. The `<reason>` text
  and the `expires:` clause are separated by ` | `. The `<reason>` portion
  remains required and human-readable. The `expires:` clause is optional.

- **AC-3 — Expired marker detection (WARN, not FAIL):**
  Given a ref-allow marker whose `expires: YYYY-MM-DD` date is earlier than
  the date CI runs, when the relevant detector processes that line, then the
  detector emits a WARN-level message identifying the file, line number, expiry
  date, and reason string. The detector does not exit with a non-zero code
  solely due to an expired marker; expiry warnings are advisory.

- **AC-4 — Non-expired marker unchanged behavior:**
  Given a ref-allow marker whose `expires: YYYY-MM-DD` date is today or later,
  when the relevant detector processes that line, then the line is suppressed
  exactly as it was before this milestone: no WARN, no FAIL, no changed output.

- **AC-5 — No-expiry marker unchanged behavior (grandfather):**
  Given a ref-allow marker with no `expires:` clause (the pre-#18 format),
  when the relevant detector processes that line, then the line is suppressed
  exactly as before: no WARN, no FAIL, no changed output. This is the
  grandfather rule that covers all existing markers in the repository at ship time.

- **AC-6 — Five-detector consistency:**
  Given the five detectors that consume `<!-- ref-allow: -->` today
  (`check-bilingual-parity.sh`, `check-dangling-refs.sh`,
  `check-ecc-delegation-consistency.sh`, `check-roadmap-drift.sh`,
  `check-research-tier-auth.sh`), when this milestone ships, then all five
  apply the expiry-detection logic consistently: same WARN format, same
  ISO 8601 date parsing, same grandfather behavior for no-expiry markers.

- **AC-7 — No regression on existing detectors and test suites:**
  Given the six canonical detectors (`check-bilingual-parity.sh`,
  `check-dangling-refs.sh`, `check-ecc-delegation-consistency.sh`,
  `check-roadmap-drift.sh`, `check-research-tier-auth.sh`,
  `check-skill-invariants.sh`) and their seven test suites
  (`test-check-bilingual-parity.sh`, `test-check-dangling-refs.sh`,
  `test-check-ecc-delegation-consistency.sh`, `test-check-roadmap-drift.sh`,
  `test-check-research-tier-auth.sh`, `test-check-skill-invariants.sh`,
  and the CI base runner), when this milestone's implementation lands, then
  all existing tests pass without modification. No existing ref-allow marker
  in the repository produces a new WARN or FAIL.

- **AC-8 — Grandfather scope defined:**
  Given all `<!-- ref-allow: ... -->` markers present in the repository at
  the time this milestone ships (template-internal markers in `specs/`,
  `.claude/meta/adr/`, `.claude/CLAUDE.md`, `.claude/agents/`, `.claude/meta/scripts/`),
  when CI runs after this milestone, then none of those markers produce a
  WARN due to the absence of an `expires:` clause. The grandfather rule
  applies unconditionally to no-expiry markers and is not time-limited.

- **AC-9 — WARN message format specified:**
  Given an expired ref-allow marker, when a detector emits a WARN, then the
  message includes: the string `[WARN]`, the file path relative to repo root,
  the line number, the expiry date, and the reason text. Example format:
  `[WARN] specs/18-ci-exemption-allowlist-expiry.md:42 ref-allow expired 2026-06-01: <reason>`. <!-- ref-allow: illustrative WARN message example referencing a fictional line 42 inside this Spec file, not a real path lookup -->


- **AC-10 — Review cadence ownership documented:**
  Given the implementation of this mechanism, when the architect and
  technical-writer complete their steps, then CLAUDE.md or the relevant
  agent instruction file documents that: (a) template maintainers own
  review of expired ref-allow markers in template-internal files
  (`specs/`, `.claude/meta/adr/`, `.claude/CLAUDE.md`, `.claude/agents/`);
  (b) fork maintainers own review of markers in their derived repositories;
  (c) the technical-writer is responsible for removing markers that have
  become over-suppressions (i.e., the referenced artifact now exists on disk)
  as part of step-7 documentation work for each milestone.

- **AC-11 — Default for omitted expiry:**
  Given a newly authored ref-allow marker without an `expires:` clause,
  when CI runs, then no WARN is emitted (the no-expiry form is valid and
  permanent under the grandfather rule). The architecture decision (ADR)
  may recommend a convention for when to include an expiry date, but CI
  does not enforce the presence of an `expires:` clause on new markers.

- **AC-12 — Implementation mechanism deferred to architect:**
  Given this Spec defines what must be detectable (AC-1 through AC-11),
  when the architect produces the ADR for this milestone, then the ADR
  decides whether the expiry logic is: (a) added as an amendment to each
  of the five existing ref-allow-consuming detectors; (b) extracted into a
  shared shell function sourced by those detectors; or (c) implemented as
  a separate sixth-plus detector script. The Spec does not mandate the
  mechanism; it mandates the observable behavior.

- **AC-13 — Existing ref-allow markers in template are counted and catalogued
  at implementation time:**
  Given the implementer begins work on this milestone, when they start the
  implementation step, then they enumerate all existing no-expiry ref-allow
  markers in the template repository (the grandfather population) and record
  the count in the implementation commit message or a code comment, so the
  review baseline is traceable.

## Key interactions

- **product-manager:** Authors this Spec (current step). Flips Roadmap #18 from
  `☐ todo` to `◐ in-progress` atomically with Spec authoring.
- **architect:** Applies the ADR-018 Alternative-B triad (new contract boundary
  + new keying/mechanism + new structural artifact) to determine whether a new
  ADR (ADR-022) is warranted.
  If the expiry-detection logic constitutes a new structural convention (new
  MECE partition in the detector family), ADR-022 is created in
  `.claude/meta/adr/`; if it is a consequence-clarification of the existing
  ref-allow escape-hatch design (ADR-015 amendment), an amendment to
  ADR-015 may suffice. The architect's decision determines which path.
- **implementer:** Treats each AC as a verbatim contract. Implements expiry
  detection consistently across the five detectors (AC-6). Does not modify
  `check-skill-invariants.sh` or the three artifact-self-keyed carve-outs
  (Non-goals). Enumerates and records the grandfather population (AC-13).
  Runs all seven existing test suites to verify AC-7.
- **code-reviewer:** Verifies AC-6 (five-detector consistency), AC-7 (no
  regression), AC-8 (grandfather scope), and AC-9 (WARN message format)
  independently against real files and CI output, not just the diff.
- **technical-writer:** At step 7 — (a) adds one CHANGELOG entry under
  `## [Unreleased]` in the `### Added` or `### Changed` subsection recording
  the expiry mechanism; (b) authors `specs/18-ci-exemption-allowlist-expiry.ja.md`
  (JA sibling, heading-tree parity verified per Roadmap #06 ownership); (c)
  reviews all ref-allow markers in this Spec file and removes any that have
  become over-suppressions once their referenced artifacts exist on disk.

## Metrics

- **Leading:** Count of existing ref-allow markers in the repository at ship time
  that are covered by the grandfather rule (AC-8). Initial baseline expected:
  roughly 20-40 markers across `specs/`, `.claude/meta/adr/`, `.claude/agents/`,
  and `.claude/meta/scripts/`. Tracked in the implementation commit message
  (AC-13).
- **Leading:** All seven existing test suites pass with zero modifications (AC-7).
  Measurable immediately at implementation time via CI run.
- **Lagging:** Reduction in over-suppression incidents (ad-hoc technical-writer
  adjudication per milestone, as seen in #16 and #17) over the 12 months after
  ship. Qualitative observation; not CI-enforced.
- **Lagging:** Zero new permanent no-expiry ref-allow markers added in template
  milestones after #18 that later require ad-hoc adjudication, as identified
  in retrospective reviews. Qualitative; architect or orchestrator monitors.

## Risks and open questions

- **Grandfather scope ambiguity for derived repositories.** The grandfather rule
  (AC-8) is defined for the template repository at ship time. Derived repositories
  that fork the template after #18 ships will inherit the updated detectors.
  Their existing ref-allow markers will also be covered by the no-expiry
  grandfather (AC-5), so no breaking change. However, derived repositories that
  update (pull upstream) to pick up the new detectors mid-project may have ref-allow
  markers added between their fork date and the update. These are also covered
  by AC-5 (no-expiry = permanent grandfather). The risk is low; the WARN is
  advisory only (AC-3).
- **WARN signal visibility.** If CI does not surface WARN messages prominently
  (e.g., they are buried in verbose output), expired markers may go unnoticed.
  The architect's ADR should specify whether expired-marker WARNs are aggregated
  at the end of each detector run, and whether a CI job summary section is
  updated. This is an implementation detail for the ADR, not a change to this
  Spec's ACs.
- **Expiry date choice convention.** The Spec mandates the `expires: YYYY-MM-DD`
  syntax (AC-2) but does not mandate when authors must set the date. An author
  who sets an expiry date of 2099-01-01 is technically compliant but defeats the
  purpose. The architect's ADR should recommend a convention (e.g., expiry =
  milestone target date + 90 days) without making it a CI gate.
- **Five-detector amendment scope.** Amending five separate detector scripts to
  share expiry logic risks inconsistency if future detectors are added and the
  shared logic is not extracted. The architect's ADR should consider whether a
  shared shell library (e.g., `ref-allow-lib.sh` sourced by all detectors) is
  warranted, or whether copy-paste-with-test is acceptable at the current scale
  of six detectors.
- **Interaction with check-bilingual-parity.sh dual-mode scanning.** The bilingual
  parity detector uses `ref-allow` in two separate scan passes (heading-key
  extraction and content-line scanning). The expiry-detection logic must be
  applied in both passes consistently; the architect's ADR should verify this.

## Out of scope

- Artifact-self-keyed exemptions: `check-skill-invariants.sh` `is_exempt()`,
  ADR-017 absence-of-claim exemption, ADR-014 Reservation-rule carve-out.
  These are computed from artifact structure, not human-authored strings; their
  lifecycle is categorically different (see Non-goals).
- Modification to `workaround-tracker.yml` `expires_on` / `expiry_warning_days`
  fields (upstream-workaround registry entries, separate mechanism, see Non-goals).
- ADR-015 amendment vocabulary carve-out (`absent` / `default-off` / `opt-in`
  structural keying) — structurally computed, out of scope.
- Path allowlist creation of any kind (ADR-015 amendment anti-pattern).
- Concrete implementation of the expiry-detection logic (architect/implementer,
  not this Spec — see AC-12).
- CHANGELOG edit (technical-writer at step 7).
- JA sibling authoring (technical-writer at step 7).
- Hard FAIL for expired markers (WARN only — see Non-goals).
- Any change to the `<!-- ref-allow: <reason> -->` no-expiry form's semantics
  (permanent grandfather, unchanged suppression behavior — AC-5).

## References

- Roadmap row: #18
- `specs/04-dangling-reference-detector.md` — defines the original ref-allow
  escape-hatch syntax and semantics; the source of truth for what the escape
  hatch means
- `.claude/meta/adr/015-dangling-reference-detector.md` — ADR-015 amendment
  explicitly anti-pattern-classifies path allowlists; defines the vocabulary
  carve-out (WARN-not-FAIL philosophy)
- `.claude/meta/adr/017-roadmap-drift-detector.md` — absence-of-claim exemption
  prior art; structural keying reference
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — `expires_on` prior art
  for time-bounded lifecycle tracking (different mechanism, same intent)
- `.github/workaround-tracker.yml` — existing `expiry_warning_days: 14` reference
  implementation for WARN-not-FAIL expiry signaling
- `.claude/meta/scripts/check-dangling-refs.sh` — canonical ref-allow consumer;
  ADR-015 amendment vocabulary carve-out and ADR-014 Reservation-rule carve-out
  live here
- `.claude/meta/scripts/check-bilingual-parity.sh` — ref-allow consumer with
  dual-pass scanning
- `.claude/meta/scripts/check-ecc-delegation-consistency.sh` — ref-allow consumer
- `.claude/meta/scripts/check-roadmap-drift.sh` — ref-allow consumer; ADR-017
  absence-of-claim keying lives here
- `.claude/meta/scripts/check-research-tier-auth.sh` — fifth ref-allow consumer
- `.claude/meta/adr/022-ci-exemption-expiry.md`
  — ADR for this milestone (Accepted — 2026-05-20)
