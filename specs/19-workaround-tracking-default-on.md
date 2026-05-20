# Workaround Tracking Default-On

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap row #19

## Problem

The template ships `.github/workaround-tracker.yml` with `enabled: false`. A
fork that clones the template and immediately starts accumulating upstream
workarounds gets no CI signal until a maintainer remembers to flip a config
switch — a step that is easy to omit, especially on projects where the first
workaround appears weeks after the initial fork. The result is that the
tracking layer exists on disk but silently does nothing, giving the
maintainer false confidence that the project has no managed workarounds when
in fact no tracking is active at all.

ADR-006 Principle 1 deliberately chose default-off with the stated rationale:
"There is no penalty for staying off. Projects with zero workarounds get zero
CI noise." This was sound at ADR-006 authoring time. However, the template's
companion milestones (#01 and the forthcoming #20) have established a
consistent precedent: once a CI scaffold is stable and its default state is
known safe for an empty inventory, it ships active by default so forks inherit
real protection without a manual activation step. The cost of activating
workaround tracking on a project with zero workarounds is precisely zero CI
noise (all three jobs short-circuit on empty inputs); the cost of leaving it
off is that the entire tracking layer is invisible to maintainers who did not
read ADR-006 closely enough to flip the switch.

Milestone #19 therefore evaluates whether the default for `enabled` in
`.github/workaround-tracker.yml` should move from `false` to `true`, and
delivers whichever outcome the architect's ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> determines is consistent
with the template's overall default-active convention.

## Goals

- The template ships with workaround tracking in a state that does not require
  a manual activation step for fork maintainers who wish to use it.
- A fork cloned from the post-#19 template and immediately subjected to a PR
  workflow receives CI coverage from `workaround-check.yml` without any
  configuration change.
- The `workaround-check.yml` short-circuit logic (all three jobs gate on
  `steps.cfg.outputs.enabled == 'true'`) remains correct and unchanged in
  observable behavior, regardless of which config value is used as the default.
- The `workarounds/` directory is absent from the template body after this
  milestone ships, confirming no real workaround entries are introduced.
- All seven canonical detectors and their eight test suites pass with
  EXIT=0 after this milestone's changes land.

## Non-goals

- **Implementation mechanism is deferred to ADR-023.** <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> Whether this milestone
  is achieved by editing `enabled: false` → `enabled: true` in
  `.github/workaround-tracker.yml`, by amending ADR-006 Principle 1, by
  issuing a superseding ADR-023, or by a different structural approach is an <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  architect decision. The Spec defines the observable outcomes only.
- **No amendment to ADR-006 Principle 1 by this Spec.** Whether ADR-006
  Principle 1 ("Default-off, single switch") is upheld, amended, or superseded
  is resolved by ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> This Spec makes no prejudgment.
- **No modification to the `workaround-check.yml` short-circuit logic.** The
  three-job gating on `steps.cfg.outputs.enabled == 'true'` is correct,
  security-motivated (the `dependabot-annotate` job's `pull_request_target`
  gates are load-bearing), and is outside scope. The ADR-006 Out-of-scope
  prohibition on adding `pull_request_target` to other jobs is unchanged.
- **No modification to `expires_on` / `expiry_warning_days` in
  `.github/workaround-tracker.yml`.** These fields govern upstream-workaround
  registry entries, not CI exemption markers. They are the ADR-006 mechanism
  and are categorically separate from the ADR-022 ref-allow expiry mechanism
  introduced in #18. #19 does not alter either field.
- **No real workaround entries added to `workarounds/`.** The template body
  ships no actual workaround registry files. The directory is expected to
  remain absent.
- **MECE with #16–#18.** #16 owned ADR-001 Status vocabulary correction; #17
  owned ADR-002/003/004 normalization and CHANGELOG sync; #18 owned the CI
  exemption (ref-allow) expiry lifecycle. #19 owns the workaround-tracker
  default-on transition exclusively.
- **MECE with #20.** Roadmap #20 ("Commit `compliance.yml` as active default")
  applies the same default-active pattern to the compliance scaffold. #19 and
  #20 are structurally parallel but non-overlapping: #19 targets
  `.github/workaround-tracker.yml`; #20 targets `.claude/compliance.yml`.
  Implementation of one does not constitute implementation of the other.
- **No CHANGELOG edit at Spec-authoring time.** The technical-writer adds the
  CHANGELOG entry at step 7 of the development workflow, not during Spec
  authoring.
- **No JA sibling authored by this Spec.** `specs/19-workaround-tracking-default-on.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  is authored by the technical-writer at step 7. Its heading-tree parity is
  governed by Roadmap #06.
- **No update to `.claude/CLAUDE.md` `### Upstream workaround lifecycle` section
  at Spec-authoring time.** That section's "ships default-off" language may
  require updating to reflect the post-#19 state. Whether and how that text
  changes is part of ADR-023's design scope <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> and is implemented by the
  technical-writer at step 7, not by this Spec.

## User stories

| As a...                        | I want to...                                                                         | So that...                                                                                             |
|-------------------------------|--------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| fork maintainer                | clone the template and immediately have workaround tracking active in CI             | I do not need to read ADR-006 to discover and flip a configuration switch before CI coverage begins    |
| implementer adding a workaround | place a `WORKAROUND-UPSTREAM` marker and registry entry without enabling any config | the CI scaffold already validates marker/registry consistency on my first PR                           |
| code-reviewer validating a PR  | see the marker-consistency job run without any project-setup prerequisite            | I can rely on CI feedback rather than checking whether the config was activated                        |
| template maintainer            | confirm that a project with zero workarounds produces zero CI noise under default-on | I can confidently recommend the default without risk of false-positive failures in new forks           |

## Acceptance criteria

- **AC-1 — Default `enabled` value in shipped template:**
  Given the post-#19 template, when a fork is created without modifying
  `.github/workaround-tracker.yml`, then the `enabled` field reads `true`
  (or is absent with a default that the workflow interprets as `true`).
  The exact mechanism (field edit vs. fallback logic) is decided by ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->

- **AC-2 — CI short-circuit logic unchanged:**
  Given `workaround-check.yml` as it exists today (three jobs, each
  gating on `steps.cfg.outputs.enabled == 'true'`), when this milestone
  ships, then the short-circuit logic is byte-for-byte unchanged. No new
  `if:` clauses are added; no existing gates are removed. The
  `dependabot-annotate` job's `pull_request_target` gates (`github.actor
  == 'dependabot[bot]'` and `pull_request.head.repo.full_name ==
  github.repository`) are preserved without modification.

- **AC-3 — Zero CI noise on empty inventory:**
  Given a fork with `enabled: true` (post-#19 default) and no files in
  `workarounds/` (the template's shipped state), when `workaround-check.yml`
  runs on a PR, then the `marker-consistency` job completes with exit code 0
  and produces a step summary showing `Markers found: 0` and
  `Active registry entries: 0`. No false-positive failures occur.

- **AC-4 — `workarounds/` absent from template body:**
  Given the post-#19 commit, when `ls workarounds/` is run at repo root,
  then the directory does not exist (or contains only a `.gitkeep` if
  required by Git conventions). No real registry entry files are present.

- **AC-5 — ADR-006 consistency is addressed in writing:**
  Given the potential conflict between this milestone and ADR-006
  Principle 1 ("Default-off, single switch"), when the architect completes
  the design step, then either (a) a new ADR-023 exists <!-- ref-allow: counterfactual reference in OR-condition; architect may choose path (a) ADR-023 or (b) ADR-006 amendment | expires: 2026-06-20 --> and explicitly
  addresses whether ADR-006 Principle 1 is upheld, amended, or
  superseded, recording the rationale; or (b) ADR-006 itself receives an
  amendment that explicitly addresses Principle 1 (upheld / amended /
  superseded) and records the rationale. The Spec does not prescribe
  which path the architect takes; AC-5 is satisfied when either (a) or
  (b) exists on disk and contains that resolution. The architect applies
  the ADR-018 Alternative-B triad discriminator to decide between paths.

- **AC-6 — Seven canonical detectors all EXIT=0:**
  Given the seven canonical detectors (`check-bilingual-parity.sh`,
  `check-dangling-refs.sh`, `check-ecc-delegation-consistency.sh`,
  `check-roadmap-drift.sh`, `check-ref-allow-expiry.sh`,
  `check-research-tier-auth.sh`, `check-skill-invariants.sh`), when each
  is run against the post-#19 repository state, then all seven exit with
  code 0. If this milestone introduces an eighth detector, the Spec
  accommodates it and AC-6 extends to include it.

- **AC-7 — Eight canonical test suites all pass:**
  Given the eight canonical test suites (`test-check-bilingual-parity.sh`,
  `test-check-dangling-refs.sh`, `test-check-ecc-delegation-consistency.sh`,
  `test-check-ref-allow-expiry.sh`, `test-check-roadmap-drift.sh`,
  `test-check-research-tier-auth.sh`, `test-check-skill-invariants.sh`,
  and the CI base runner), when each is run against the post-#19 repository
  state, then all eight pass without modification to existing test logic.
  If this milestone introduces a ninth test suite, AC-7 extends to include it.

- **AC-8 — Roadmap row #19 reflects ship state:** <!-- ref-allow: .claude/meta/adr/023-*.md is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  Given the post-#19 commit, when `.claude/CLAUDE.md` is read, then
  Roadmap row #19 shows `☑ done`, the `spec:` link resolves to
  `specs/19-workaround-tracking-default-on.md`, and if ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> was issued,
  the `adr:` link resolves to `.claude/meta/adr/023-*.md`.

- **AC-9 — No regression in `annotate_dependabot_prs: false` default:**
  Given the post-#19 `.github/workaround-tracker.yml`, when `annotate_dependabot_prs`
  is inspected, then its value remains `false`. The `dependabot-annotate`
  job is an opt-in overlay on top of the core tracking; its default is
  not changed by this milestone.

- **AC-10 — No regression in `fail_on_marker_drift: false` default:**
  Given the post-#19 `.github/workaround-tracker.yml`, when
  `fail_on_marker_drift` is inspected, then its value remains `false`.
  Drift is reported as a warning in the step summary, not a pipeline failure,
  preserving the ADR-006 conservative default for new forks.

- **AC-11 — CHANGELOG entry present:**
  Given the post-#19 state after step 7, when `CHANGELOG.md` is read,
  then a `### Changed` or `### Added` entry under `## [Unreleased]` records
  the default-on transition for workaround tracking. The technical-writer
  authors this entry at step 7.

- **AC-12 — JA sibling heading-tree parity:**
  Given the post-#19 state after step 7, when `specs/19-workaround-tracking-default-on.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  is read, then its heading tree matches the EN Spec's heading tree exactly
  (per Roadmap #06 parity ownership). The technical-writer authors this file
  at step 7.

## Key interactions

- **product-manager:** Authors this Spec (current step). Flips Roadmap #19
  from `☐ todo` to `◐ in-progress` atomically with Spec authoring.
- **architect:** Applies the ADR-018 Alternative-B triad discriminator (new
  contract boundary + new keying/mechanism + new structural artifact) to
  determine whether ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> is warranted and what relationship it has to
  ADR-006. The architect's decision governs AC-1 and AC-5. If ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> is
  issued, the architect adds the `adr:` link to Roadmap row #19.
- **implementer:** Treats each AC as a verbatim contract. Modifies only the
  file(s) directed by ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> Does not add real workaround entries (AC-4).
  Does not modify the short-circuit logic (AC-2). Runs all canonical detectors
  and test suites to verify AC-6 and AC-7.
- **code-reviewer:** Verifies AC-2 (short-circuit logic unchanged), AC-3
  (zero noise on empty inventory), AC-4 (no registry entries), and AC-9/AC-10
  (conservative opt-in defaults preserved) independently against real files.
- **technical-writer:** At step 7 — (a) adds one CHANGELOG entry (AC-11);
  (b) authors `specs/19-workaround-tracking-default-on.ja.md` (AC-12); <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  (c) reviews whether the `### Upstream workaround lifecycle` section in
  `.claude/CLAUDE.md` ("ships default-off") requires updating to match the
  post-#19 state, and if so, updates it (this edit is in scope at step 7,
  not during Spec authoring).

## Metrics

- **Leading:** EXIT=0 from all seven (or eight) canonical detectors after
  implementation, measured via the `make check` or equivalent CI run.
  Immediately verifiable at implementation time.
- **Leading:** All eight (or nine) canonical test suites pass without
  modification to existing test logic. Measurable at implementation time.
- **Lagging:** Reduction in newly forked projects that have no workaround
  tracking active six months after forking (qualitative observation; not
  CI-enforced). The expectation is that default-on eliminates the class of
  "forgot to flip the switch" failures entirely.

## Risks and open questions

- **ADR-006 Principle 1 conflict.** ADR-006 explicitly considered and
  rejected "Default-on CI workflow" as an alternative: "Inflicts maintenance
  cost on projects with zero workarounds; conflicts with the template's
  existing default-off convention." That reasoning may not hold for a template
  whose parallel scaffolds (#01, #20) consistently ship active. The architect's
  ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> must address whether the template-level default-active convention
  now supersedes the feature-level default-off Principle 1, or whether Principle
  1 is retained and the default is achieved via a different mechanism (e.g.,
  workflow fallback logic rather than a config field change). This is the
  primary open question for ADR-023. <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- **Fork update path.** Projects that forked the template before #19 and have
  never changed `enabled` will have `enabled: false` in their config. The
  default-on change only affects new forks or forks that pull the upstream
  change. Existing forks are not automatically updated. This is the correct
  behavior (no forced disruption), but the technical-writer should note it
  in the CHANGELOG entry.
- **`annotate_dependabot_prs` interaction.** The `dependabot-annotate` job
  uses `pull_request_target`, a high-risk trigger. The job is already gated
  behind `annotate_dependabot_prs: false` by default (AC-9). Changing `enabled`
  to `true` without changing `annotate_dependabot_prs` means the annotation
  job will still not run. This is the intended layered activation model and
  should be documented in the CHANGELOG entry.
- **`fail_on_marker_drift` interaction.** With tracking active and an empty
  registry, orphan-marker count is 0 and orphan-entry count is 0. However,
  if a fork inadvertently adds a `WORKAROUND-UPSTREAM` marker without a
  registry entry, `fail_on_marker_drift: false` means the mismatch is
  reported but does not break the build. AC-10 preserves this conservative
  default.

## Out of scope

- ADR-006 Principle 1 amendment or supersession (architect, via ADR-023). <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- `workaround-check.yml` short-circuit logic or trigger modifications.
- `pull_request_target` expansion to other jobs (ADR-006 Out of scope, forbidden).
- `expires_on` / `expiry_warning_days` field changes in `workaround-tracker.yml`
  (these are registry-entry fields, separate from this milestone's scope).
- Real workaround registry entries in `workarounds/` (template body stays empty).
- Per-ecosystem lockfile version-comparison jobs (ADR-006 Out of scope).
- CHANGELOG edit at Spec-authoring time (technical-writer at step 7).
- JA sibling authoring at Spec-authoring time (technical-writer at step 7).
- `.claude/CLAUDE.md` `### Upstream workaround lifecycle` section text update
  at Spec-authoring time (technical-writer at step 7, conditional on ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  outcome).
- #20 ("Commit `compliance.yml` as active default") — structurally parallel
  but a separate milestone.

## References

- Roadmap row: #19
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — ADR-006; Principle 1
  ("Default-off, single switch") and the "Default-on CI workflow" rejected
  alternative are the primary tension this milestone resolves via ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- `.github/workaround-tracker.yml` — current config shipped with `enabled: false`
- `.github/workflows/workaround-check.yml` — three-job CI scaffold; short-circuit
  logic and `dependabot-annotate` security gates are load-bearing
- `specs/01-ship-verification-yml-committed.md` — precedent for shipping a CI
  scaffold active by default (#01 milestone)
- `specs/20-ship-compliance-yml-committed.md` <!-- ref-allow: specs/20-ship-compliance-yml-committed.md is reserved (Roadmap row #20) but not yet authored; forward reference | expires: 2026-06-20 --> — structurally parallel forthcoming
  milestone (#20); MECE boundary noted in Non-goals
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Spec reservation
  rule and 1:1 milestone↔Spec mapping
- `.claude/meta/references/upstream-workaround-tracking.md` — day-to-day usage
  details; "Default-off opt-in (single switch)" section
